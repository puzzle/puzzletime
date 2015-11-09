# encoding: utf-8

class Order::Report

  include Filterable

  attr_reader :params

  def initialize(params = {})
    @params = params
  end

  def each(&block)
    section = entries[((current_page - 1) * limit_value)...(current_page * limit_value)]
    section.each(&block)
  end

  def entries
    @entries ||= load_entries
  end

  def current_page
    (params[:page] || 1).to_i
  end

  def total_pages
    (entries.size / limit_value.to_f).ceil
  end

  def limit_value
    30
  end

  private


  def load_entries
    orders = load_orders
    accounting_posts = load_accounting_posts(orders)
    hours = hours_to_hash(load_accounting_post_hours(accounting_posts.values.flatten))
    invoices = invoices_to_hash(load_invoices(orders))
    orders.collect { |o| build_entry(o, accounting_posts, hours, invoices) }
  end

  def load_orders
    entries = Order.list.includes(:status, targets: :target_scope)
    # TODO: filter by from, until, target
    entries = filter_entries_by_parent(entries)
    filter_entries_by(entries, :kind_id, :responsible_id, :status_id, :department_id)
    # TODO paginate depending on sort attr
  end

  def load_accounting_posts(orders)
    AccountingPost.select('accounting_posts.id, accounting_posts.offered_total, accounting_posts.offered_rate, orders.id AS order_id').
                   joins(:work_item).
                   joins('INNER JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)').
                   where(orders: { id: orders.collect(&:id) }).
                   group_by(&:order_id)
  end

  def load_accounting_post_hours(accounting_posts)
    Worktime.joins(:work_item).
             joins('INNER JOIN accounting_posts ON accounting_posts.work_item_id = ANY (work_items.path_ids)').
             where(accounting_posts: { id: accounting_posts.collect(&:id) }).
             group('accounting_posts.id, worktimes.billable').
             pluck('accounting_posts.id, worktimes.billable, SUM(worktimes.hours)')
  end

  def load_invoices(orders)
    Invoice.where(order_id: orders.collect(&:id)).
            group('order_id').
            pluck('order_id, SUM(total_amount) AS total_amount, SUM(total_hours) AS total_hours')
  end

  def hours_to_hash(result)
    result.each_with_object(Hash.new { |h, k| h[k] = Hash.new(0) }) do |row, hash|
      hash[row.first][row.second] = row.last
    end
  end

  def invoices_to_hash(result)
    result.each_with_object(Hash.new { |h, k| h[k] = Hash.new(0) }) do |row, hash|
      hash[row.first][:total_amount] = row[1]
      hash[row.first][:total_hours] = row[2]
    end
  end

  def build_entry(order, accounting_posts, hours, invoices)
    posts = accounting_posts[order.id] || {}
    Order::Report::Entry.new(order, posts, hours, invoices[order.id])
  end

  def sort_entries_by_target_scope(entries)
    match = params[:sort].to_s.match(/\Atarget_scope_(\d+)\z/)
    if match
      entries.order_by_target_scope(match[1])
    else
      entries
    end
  end

  def filter_entries_by_parent(entries)
    if params[:category_work_item_id].present?
      entries.where('? = ANY (work_items.path_ids)', params[:category_work_item_id])
    elsif params[:client_work_item_id].present?
      entries.where('? = ANY (work_items.path_ids)', params[:client_work_item_id])
    else
      entries
    end
  end

  def select_offered_total(entries)
    entries.joins('LEFT JOIN work_items post_items ON work_items.id = ANY (post_items.path_ids)').
      joins('LEFT JOIN accounting_posts ON accounting_posts.work_item_id = post_items.id').
      group('orders.id, work_items.id').
      select('orders.*, work_items.*, SUM(accounting_posts.offered_total) AS offered_total')
  end

  def select_supplied_service_hours(entries)
    entries.joins('LEFT JOIN work_items time_items ON work_items.id = ANY (time_items.path_ids)').
      joins('LEFT JOIN worktimes ON worktimes.work_item_id = time_items.id').
      select('SUM(worktimes.hours) AS supplied_hours')
  end

end
