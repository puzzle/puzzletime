module Plannings
  class EmployeeBoard < Board

    attr_reader :employee

    def initialize(employee, period)
      super(period)
      @employee = employee
    end

    def row_legend(_employee_id, work_item_id)
      accounting_posts.detect { |post| post.work_item_id == work_item_id.to_i }
    end

    private

    def load_plannings
      super.where(employee_id: employee.id)
    end

    def load_employees
      [employee]
    end

  end
end
