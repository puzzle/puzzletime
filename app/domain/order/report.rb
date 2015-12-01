# encoding: utf-8

class Order::Report
  include Filterable

  attr_reader :period, :params

  def initialize(period, params = {})
    @period = period
    @params = params
  end

  def page(&block)
    section = entries[((current_page - 1) * limit_value)...(current_page * limit_value)]
    ([total] + section).each(&block) if section.present?
  end

  def entries
    @entries ||= Order.benchmark('load all') { sort_entries(load_entries) }
  end

  def total
    @total ||= Order::Report::Total.new(self)
  end

  def to_csv
    entries
    scopes = TargetScope.list.to_a
    Order.benchmark('csv') do
      CSV.generate do |csv|
        csv << csv_header(scopes)

        entries.each do |e|
          csv << csv_row(e, scopes)
        end
      end
    end
  end

  def current_page
    (params[:page] || 1).to_i
  end

  def total_pages
    (entries.size / limit_value.to_f).ceil
  end

  def limit_value
    20
  end

  def present?
    entries.present?
  end

  def filters_defined?
    filters = params.except(:action, :controller, :format, :utf8, :page, :clear)
    filters.present? && filters.values.any?(&:present?)
  end

  private

  def load_entries
    orders = Order.benchmark('orders') { load_orders.to_a }
    accounting_posts = Order.benchmark('accounting posts') { accounting_posts_to_hash(load_accounting_posts(orders)) }
    hours = Order.benchmark('hours') { hours_to_hash(load_accounting_post_hours(accounting_posts.values)) }
    invoices = Order.benchmark('invoices') { invoices_to_hash(load_invoices(orders)) }
    orders.collect { |o| build_entry(o, accounting_posts, hours, invoices) }.compact
  end

  def load_orders
    entries = Order.list.includes(:status, :targets)
    entries = filter_by_parent(entries)
    entries = filter_by_target(entries)
    filter_entries_by(entries, :kind_id, :responsible_id, :status_id, :department_id)
  end

  def load_accounting_posts(orders)
    AccountingPost.joins(:work_item).
                   joins('INNER JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)').
                   where(orders: { id: orders.collect(&:id) }).
                   pluck('orders.id, accounting_posts.id, accounting_posts.offered_total, ' \
                         'accounting_posts.offered_rate, accounting_posts.offered_hours')
  end

  def accounting_posts_to_hash(result)
    result.each_with_object(Hash.new { |h, k| h[k] = {} }) do |row, hash|
      hash[row.first][row[1]] = { offered_total: row[2],
                                  offered_rate: row[3],
                                  offered_hours: row[4] }
    end
  end

  def load_accounting_post_hours(accounting_posts)
    Worktime.joins(:work_item).
             joins('INNER JOIN accounting_posts ON ' \
                   'accounting_posts.work_item_id = ANY (work_items.path_ids)').
             where(accounting_posts: { id: accounting_posts.collect(&:keys).flatten }).
             in_period(period).
             group('accounting_posts.id, worktimes.billable').
             pluck('accounting_posts.id, worktimes.billable, SUM(worktimes.hours)')
  end

  def hours_to_hash(result)
    result.each_with_object(Hash.new { |h, k| h[k] = Hash.new(0) }) do |row, hash|
      hash[row.first][row.second] = row.last
    end
  end

  def load_invoices(orders)
    Invoice.where(order_id: orders.collect(&:id)).
            where(period.where_condition('billing_date')).
            group('order_id').
            pluck('order_id, SUM(total_amount) AS total_amount, SUM(total_hours) AS total_hours')
  end

  def invoices_to_hash(result)
    result.each_with_object(Hash.new { |h, k| h[k] = Hash.new(0) }) do |row, hash|
      hash[row.first][:total_amount] = row[1]
      hash[row.first][:total_hours] = row[2]
    end
  end

  def build_entry(order, accounting_posts, hours, invoices)
    posts = accounting_posts[order.id]
    post_hours = hours.slice(*posts.keys)
    if post_hours.values.any? { |h| h.values.sum > 0.0001 }
      Order::Report::Entry.new(order, posts, post_hours, invoices[order.id])
    end
  end

  def filter_by_parent(orders)
    if params[:category_work_item_id].present?
      orders.where('? = ANY (work_items.path_ids)', params[:category_work_item_id])
    elsif params[:client_work_item_id].present?
      orders.where('? = ANY (work_items.path_ids)', params[:client_work_item_id])
    else
      orders
    end
  end

  def filter_by_target(orders)
    if params[:target].present?
      ratings = params[:target].split('_')
      orders.joins('LEFT JOIN order_targets filter_targets ON filter_targets.order_id = orders.id').
             where(filter_targets: { rating: ratings })
    else
      orders
    end
  end

  def sort_entries(entries)
    dir = params[:sort_dir] == 'desc' ? 1 : -1
    match = sort_by_target?
    if match
      sort_by_target(entries, match[1], dir)
    elsif sort_by_value?
      sort_by_value(entries, dir)
    else
      entries
    end
  end

  def sort_by_value?
    Order::Report::Entry.public_instance_methods(false).collect(&:to_s).include?(params[:sort])
  end

  def sort_by_target?
    params[:sort].to_s.match(/\Atarget_scope_(\d+)\z/)
  end

  def sort_by_value(entries, dir)
    entries.sort_by do |e|
      e.send(params[:sort]).to_f * dir
    end
  end

  def sort_by_target(entries, target_scope_id, dir)
    entries.sort_by do |e|
      dir * OrderTarget::RATINGS.index(e.target(target_scope_id).try(:rating)).to_i
    end
  end

  def csv_header(scopes)
    ['Kunde', 'Kategorie', 'Auftrag', 'Status', 'Budget', 'Geleistet',
     'Verrechenbar', 'Verrechnet', 'Verrechenbarkeit', 'Offerierter Stundensatz',
     'Verrechnete Stundensatz', 'Durchschnittlicher Stundensatz', *scopes.collect(&:name)]
  end

  def csv_row(e, scopes)
    ratings = scopes.collect { |scope| e.target(scope.id).try(:rating) }

    [e.client, e.category, e.name, e.status.to_s, e.offered_amount, e.supplied_amount,
     e.billable_amount, e.billed_amount, e.billability, e.offered_rate,
     e.billed_rate, e.average_rate, *ratings]
  end

end
