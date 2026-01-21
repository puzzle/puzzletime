# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Billing
  class Report
    include Filterable

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
      @total ||= Billing::Report::Total.new(self)
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
                              :clear)
      filters.present? && filters.values.any?(&:present?)
    end

    private

    def load_entries
      orders = load_orders.to_a
      worktimes = load_worktimes(orders)
      accounting_posts = accounting_posts_to_hash(load_accounting_posts(orders))
      hours = hours_to_hash(load_accounting_post_hours(accounting_posts.values))
      invoices = invoices_to_hash(load_invoices(orders))
      entries = orders.filter_map { |o| build_entry(o, worktimes, accounting_posts, hours, invoices) }
      entries.filter { |e| e.not_billed_hours.positive? } # Only show if there are unbilled HOURS
    end

    # prepare worktimes, as some columns take data directly from worktimes
    def load_worktimes(orders)
      Worktime.in_period(@period)
              .billable
              .joins(:work_item)
              .joins('INNER JOIN accounting_posts ON accounting_posts.work_item_id = work_items.id')
              .joins('INNER JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)')
              .where(orders: { id: orders.collect(&:id) })
              .select('orders.id AS order_id, SUM(worktimes.hours) AS hours, (worktimes.invoice_id IS NOT NULL) AS has_invoice, SUM(worktimes.hours * accounting_posts.offered_rate) AS amount')
              .group('order_id, has_invoice')
              .group_by { |time| time['has_invoice'].present? }
              .transform_values { |partition| partition.index_by(&:order_id) }
    end

    def load_orders
      entries = Order.list.includes(:status, :targets, :order_uncertainties)
      entries = filter_by_parent(entries)
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

    def build_entry(order, worktimes, accounting_posts, hours, invoices)
      posts = accounting_posts[order.id]
      post_hours = hours.slice(*posts.keys)

      Billing::Report::Entry.new(order, worktimes, posts, post_hours, invoices[order.id])
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
      dir = params[:sort_dir].to_s.casecmp('desc').zero? ? -1 : 1
      if sort_by_string?
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
      Billing::Report::Entry.public_instance_methods(false)
                            .collect(&:to_s)
                            .include?(params[:sort])
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
  end
end
