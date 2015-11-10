# encoding: utf-8

class Order::Report

  include Filterable

  attr_reader :period, :params

  def initialize(period, params = {})
    @period = period
    @params = params
  end

  def each(&block)
    section = entries[((current_page - 1) * limit_value)...(current_page * limit_value)]
    section.each(&block)
  end

  def entries
    @entries ||= Order.benchmark('load all') { sort_entries(load_entries) }
  end

  def to_csv
    entries
    Order.benchmark('csv') do
    CSV.generate do |csv|
      csv << ['Kunde', 'Kategorie', 'Auftrag', 'Status', 'Budget', 'Geleistet',
              'Verrechenbar', 'Verrechnet', 'Verrechenbarkeit', 'Offerierter Stundensatz',
              'Verrechnete Stundensatz', 'Durchschnittlicher Stundensatz']
      entries.each do |e|
        # TODO category
        csv << [e.work_item.path_names.first, '', e.name, e.status.to_s,
                e.offered_amount, e.supplied_amount,
                e.billable_amount, e.billed_amount, e.billability,
                e.offered_rate, e.billed_rate, e.average_rate]
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

  private

  def load_entries
    orders = Order.benchmark('orders') { load_orders.to_a }
    accounting_posts = Order.benchmark('accounting posts') { accounting_posts_to_hash(load_accounting_posts(orders)) }
    hours = Order.benchmark('hours') { hours_to_hash(load_accounting_post_hours(accounting_posts.values)) }
    invoices = Order.benchmark('invoices') { invoices_to_hash(load_invoices(orders)) }
    orders.collect { |o| build_entry(o, accounting_posts, hours, invoices) }.compact
  end

  def load_orders
    entries = Order.list.includes(:status, targets: :target_scope)
    # TODO: filter by  target
    entries = filter_by_parent(entries)
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
             where(accounting_posts: { id: accounting_posts.collect { |h| h.keys }.flatten }).
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
            where(period.where_condition('due_date')).
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

  def sort_entries(entries)
    return entries unless valid_sorting?

    dir = params[:sort_dir] == 'desc' ? 1 : -1
    entries.sort_by do |e|
      e.send(params[:sort]) * dir
    end
  end

  def valid_sorting?
    Order::Report::Entry.public_instance_methods(false).collect(&:to_s).include?(params[:sort])
  end

  def sort_by_target_scope(entries)
    match = params[:sort].to_s.match(/\Atarget_scope_(\d+)\z/)
    if match
      entries.order_by_target_scope(match[1])
    else
      entries
    end
  end

end

