class Order::Cockpit
  class TotalRow < Row
    def initialize(rows)
      super('Total')
      @cells = build_total_cells(rows)
    end

    private

    def build_total_cells(rows)
      columns = rows.collect(&:cells).transpose
      columns.collect do |cells|
        Cell.new(cells.sum { |c| c.hours.to_i },
                 cells.sum { |c| c.amount.to_d })
      end
    end
  end
end
