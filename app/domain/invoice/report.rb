# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Invoice
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
      @total ||= Invoice::Report::Total.new(self)
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
      invoices = load_invoices.to_a
      invoices.filter_map { |invoice| Invoice::Report::Entry.new(invoice) }
    end

    def load_invoices
      entries = Invoice.list
      entries = filter_by_parent(entries).distinct
      entries = filter_by_order_property(entries, :kind_id, :responsible_id, :department_id).distinct
      entries = entries.in_period(@period)
      filter_entries_by(entries, :status).distinct
    end

    def filter_by_order_property(entries, *keys)
      keys.inject(entries) do |filtered, key|
        if params[key].present?
          filtered.joins(:order).where(orders: { key => params[key] })
        else
          filtered
        end
      end
    end

    # filter by customer
    def filter_by_parent(invoices)
      if params[:client_work_item_id].present?
        invoices.joins(:order, :work_items).where('? = ANY (work_items.path_ids)', params[:client_work_item_id])
      else
        invoices
      end
    end

    def sort_entries(entries)
      dir = params[:sort_dir].to_s.casecmp('desc').zero? ? 1 : -1
      if sort_by_string?
        sort_by_string(entries, dir)
      elsif sort_by_number?
        sort_by_number(entries, dir)
      else
        entries
      end
    end

    def sort_by_string?
      %w[client reference responsible status billing_date due_date].include?(params[:sort])
    end

    def sort_by_number?
      %w[total_amount total_hours].include?(params[:sort])
    end

    def sort_by_string(entries, dir)
      sorted = entries.sort_by do |e|
        e.send(params[:sort])
      end
      sorted.reverse! if dir.negative?
      sorted
    end

    def sort_by_number(entries, dir)
      entries.sort_by do |e|
        e.send(params[:sort]).to_f * dir
      end
    end
  end
end
