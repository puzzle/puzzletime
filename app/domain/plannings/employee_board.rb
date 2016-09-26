module Plannings
  class EmployeeBoard < Board

    attr_reader :employee

    def initialize(employee, period)
      super(period)
      @employee = employee
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