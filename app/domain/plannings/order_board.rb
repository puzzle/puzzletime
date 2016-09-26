module Plannings
  class OrderBoard < Board

    attr_reader :order

    def initialize(order, period)
      super(period)
      @order = order
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