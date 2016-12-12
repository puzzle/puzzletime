# encoding: utf-8

module Plannings
  class OrderBoard < Board

    alias order subject

    def row_legend(employee_id, _work_item_id)
      employees.detect { |e| e.id == employee_id.to_i }
    end

    def plannable_hours
      accounting_posts.to_a.sum { |p| p.offered_hours.to_f }
    end

    private

    def load_plannings
      super.
        joins(:work_item).
        where('? = ANY (work_items.path_ids)', order.work_item_id)
    end

    def load_accounting_posts
      order.accounting_posts.
        where(closed: false).
        includes(:work_item).
        list
    end

  end
end
