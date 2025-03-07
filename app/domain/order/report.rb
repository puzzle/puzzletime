# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Order
  class Report
    include Filterable
    include OrderHelper

    attr_reader :period, :params

    def initialize(period, params = {})
      @period = period
      @params = params
    end

    def page(&)
      section = entries[((current_page - 1) * limit_value)...(current_page * limit_value)]
      ([total] + section).each(&) if section.present?
    end

    def entries
      @entries ||= sort_entries(load_entries)
    end

    def total
      @total ||= Order::Report::Total.new(self)
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

    delegate :present?, to: :entries

    def filters_defined?
      filters = params.except(:action, :controller, :format, :utf8, :page,
                              :clear, :status_preselection, :without_hours)
      filters.present? && filters.values.any?(&:present?)
    end

    private

    def load_entries
      orders = load_orders.to_a
      accounting_posts = accounting_posts_to_hash(load_accounting_posts(orders))
      hours = hours_to_hash(load_accounting_post_hours(accounting_posts.values))
      invoices = invoices_to_hash(load_invoices(orders))
      orders.filter_map { |o| build_entry(o, accounting_posts, hours, invoices) }
    end

    def load_orders
      entries = Order.list.includes(:status, :targets, :order_uncertainties)
      entries = filter_by_closed(entries)
      entries = filter_by_parent(entries)
      entries = filter_by_target(entries)
      entries = filter_by_uncertainty(entries, :major_risk_value)
      entries = filter_by_uncertainty(entries, :major_chance_value)
      filter_entries_by(entries, :kind_id, :responsible_id, :status_id, :department_id)
    end

    def load_accounting_posts(orders)
      AccountingPost.joins(:work_item)
                    .joins('INNER JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)')
                    .where(orders: { id: orders.collect(&:id) })
                    .pluck('orders.id, accounting_posts.id, accounting_posts.offered_total, ' \
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
      accounting_post_hours =
        Worktime
        .joins(:work_item)
        .joins('INNER JOIN accounting_posts ON ' \
               'accounting_posts.work_item_id = ANY (work_items.path_ids)')
        .where(accounting_posts: { id: accounting_posts.collect(&:keys).flatten })

      accounting_post_hours = accounting_post_hours.in_period(period) if params[:status_preselection].blank? || params[:status_preselection] == 'not_closed'

      accounting_post_hours
        .group('accounting_posts.id, worktimes.billable')
        .pluck('accounting_posts.id, worktimes.billable, SUM(worktimes.hours)')
    end

    def hours_to_hash(result)
      result.each_with_object(Hash.new { |h, k| h[k] = Hash.new(0) }) do |row, hash|
        hash[row.first][row.second] = row.last
      end
    end

    def load_invoices(orders)
      invoices = Invoice.where(order_id: orders.collect(&:id))

      invoices = invoices.where(period.where_condition('billing_date')) if params[:status_preselection].blank? || params[:status_preselection] == 'not_closed'

      invoices
        .group('order_id')
        .pluck('order_id, SUM(total_amount) AS total_amount, SUM(total_hours) AS total_hours')
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

      return unless show_without_hours? || booked_hours?(post_hours)

      Order::Report::Entry.new(order, posts, post_hours, invoices[order.id])
    end

    def show_without_hours?
      params[:without_hours] == 'true'
    end

    def booked_hours?(post_hours)
      post_hours.values.any? { |h| h.values.sum > 0.0001 }
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
        orders.joins('LEFT JOIN order_targets filter_targets ON filter_targets.order_id = orders.id')
              .where(filter_targets: { rating: ratings })
      else
        orders
      end
    end

    def filter_by_closed(orders)
      case params[:status_preselection]
      when nil, ''
        orders
      when 'closed'
        orders.where(order_statuses: { closed: true })
              .where(period.where_condition('closed_at'))
      when 'not_closed'
        orders.where(order_statuses: { closed: false })
      end
    end

    def filter_by_uncertainty(orders, attr)
      if params[attr].present?
        orders.where(attr => map_uncertainties_filter(params[attr]))
      else
        orders
      end
    end

    def map_uncertainties_filter(value)
      case value
      when 'low'
        0..2
      when 'medium'
        3..7
      when 'high'
        8..16
      end
    end

    def sort_entries(entries)
      dir = params[:sort_dir].to_s.casecmp('desc').zero? ? 1 : -1
      match = sort_by_target?
      if match
        sort_by_target(entries, match[1], dir)
      elsif sort_by_budget?
        sort_by_budget(entries, dir)
      elsif sort_by_string?
        sort_by_string(entries, dir)
      elsif sort_by_number?
        sort_by_number(entries, dir)
      else
        entries
      end
    end

    def sort_by_string?
      %w[client].include?(params[:sort])
    end

    def sort_by_number?
      Order::Report::Entry.public_instance_methods(false)
                          .collect(&:to_s)
                          .include?(params[:sort])
    end

    def sort_by_target?
      params[:sort].to_s.match(/\Atarget_scope_(\d+)\z/)
    end

    def sort_by_budget?
      params[:sort].to_s == 'budget_controlling'
    end

    def sort_by_string(entries, dir)
      sorted = entries.sort_by do |e|
        e.send(params[:sort])
      end
      sorted.reverse! if dir.positive?
      sorted
    end

    def sort_by_number(entries, dir)
      entries.sort_by do |e|
        e.send(params[:sort]).to_f * dir
      end
    end

    def sort_by_target(entries, target_scope_id, dir)
      entries.sort_by do |e|
        dir * OrderTarget::RATINGS.index(e.target(target_scope_id).try(:rating)).to_i
      end
    end

    def sort_by_budget(entries, dir)
      entries.sort_by do |e|
        dir * get_order_budget_used_percentage(e)
      end
    end
  end
end
