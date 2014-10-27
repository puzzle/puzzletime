class Order::Cockpit
  class AccountingPostRow < Row

    attr_reader :cells, :accounting_post

    def initialize(accounting_post, label = nil)
      super(label || accounting_post.to_s)
      @accounting_post = accounting_post
      @cells = build_cells
    end

    def portfolio
      accounting_post.portfolio_item.to_s
    end

    def offered_rate
      accounting_post.offered_rate
    end

    private

    def build_cells
      [ build_budget_cell,
        build_productivity_cell,
        build_billed_cell,
        build_open_productivity_cell,
        build_not_billable_cell,
        build_remaining_cell,
        build_open_budget_cell ]
    end

    def build_budget_cell
      Cell.new(accounting_post.offered_hours, accounting_post.offered_total)
    end

    def build_productivity_cell
      hours = accounting_post_hours.values.sum
      amount = offered_rate && offered_rate * hours
      Cell.new(hours, amount)
    end

    # TODO
    def build_billed_cell
      Cell.new(nil, nil)
    end

    # TODO
    def build_open_productivity_cell
      Cell.new(nil, nil)
    end

    def build_not_billable_cell
      hours = accounting_post_hours[false]
      Cell.new(hours, nil)
    end

    # TODO
    def build_remaining_cell
      Cell.new(nil, nil)
    end

    # TODO
    def build_open_budget_cell
      Cell.new(nil, nil)
    end

    def accounting_post_hours
      @hours ||= accounting_post.worktimes.group(:billable).sum(:hours)
    end
  end
end