module Invoicing
  class Builder
    attr_accessor :invoice, :employees, :accounting_posts, :grouping

    delegate :order, to: :invoice

    def initialize(invoice = nil)
      @invoice = invoice || Invoice.new
      @grouping = :accounting_posts
    end

    def all_employees
      Employee.where(id: order.worktimes.select(:employee_id)).list
    end

    def all_accounting_posts
      order.accounting_posts.list
    end

    def save
      success = false
      Invoice.transaction do
        success = save_internal
        fail ActiveRecord::Rollback unless success
      end
      success
    end

    def build_positions
      case grouping
      when :manual then [manual_position]
      when :employees then employee_positions
      else accounting_post_positions
      end
    end

    private

    def save_internal
      positions = build_positions

      update_total_values(positions) &&
      save_remote_invoice(positions) &&
      update_worktime_invoice_ids
    end

    def update_total_values(positions)
      invoice.total_hours = positions.collect(&:total_hours).sum
      invoice.total_amount = positions.collect(&:total_amount).sum
      invoice.save
    end

    def save_remote_invoice(positions)
      Invoicing.instance.save_invoice(invoice, positions)
      true
    rescue Invoicing::Error => e
      invoice.errors.add(:base, e.message)
      false
    end

    def update_worktime_invoice_ids
      invoice.ordertimes.update_all(invoice_id: nil)
      worktimes.update_all(invoice_id: invoice.id) unless grouping == :manual
      true
    end

    def manual_position
      Position.new(AccountingPost.new, 0, 'Manuell')
    end

    def accounting_post_positions
      worktimes.group(:work_item_id).sum(:hours).collect do |work_item_id, hours|
        post = AccountingPost.find_by_work_item_id!(work_item_id)
        Position.new(post, hours)
      end.sort_by(&:name)
    end

    def employee_positions
      worktimes.group(:work_item_id, :employee_id).sum(:hours).collect do |groups, hours|
        post = AccountingPost.find_by_work_item_id!(groups.first)
        employee = Employee.find(groups.last)
        Position.new(post, hours, "#{post.name} - #{employee}")
      end.sort_by(&:name)
    end

    def selected_accounting_post_ids
      Array(accounting_posts).collect(&:work_item_id).presence ||
        all_accounting_posts.pluck(:work_item_id)
    end

    def selected_employee_ids
      Array(employees).collect(&:id).presence ||
        all_employees.pluck(:id)
    end

    def worktimes
      Ordertime.in_period(period).
        where(billable: true).
        where(work_item_id: selected_accounting_post_ids).
        where(employee_id: selected_employee_ids)
    end

    def period
      Period.new(invoice.period_from, invoice.period_to)
    end
  end
end
