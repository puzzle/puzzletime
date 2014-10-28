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

    def supplied_services_hours
      accounting_post_hours.values.sum.round
    end

    def not_billable_hours
      (accounting_post_hours[false] || 0).round
    end

    private

    def build_cells
      { budget:            build_budget_cell,
        supplied_services: build_supplied_services_cell,
        billed:            build_billed_cell,
        open_services:     build_open_services_cell,
        not_billable:      build_not_billable_cell,
        remaining:         build_remaining_cell,
        open_budget:       build_open_budget_cell }
    end

    def build_budget_cell
      Cell.new(accounting_post.offered_hours, accounting_post.offered_total)
    end

    def build_supplied_services_cell
      build_cell_with_amount(supplied_services_hours)
    end

    # TODO
    def build_billed_cell
      # (Ist-R[h])
      Cell.new(0, 0)
    end

    # TODO
    def build_open_services_cell
      # (Ist[h] - Ist-R[h])*Soll[CHF/h]
      Cell.new(0, 0)
    end

    def build_not_billable_cell
      Cell.new(not_billable_hours, nil)
    end

    def build_remaining_cell
      # Soll[h] - Ist-R[h]
      # Soll[CHF] - Ist-R[CHF]
      Cell.new(accounting_post.remaining_hours || 0, nil)
    end

    # TODO
    def build_open_budget_cell
      Cell.new(0, 0)
    end

    def build_cell_with_amount(hours)
      amount = offered_rate && offered_rate * hours
      Cell.new(hours, amount)
    end

    def accounting_post_hours
      @hours ||= accounting_post.worktimes.group(:billable).sum(:hours)
    end
  end
end