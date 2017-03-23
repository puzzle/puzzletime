class EmployeeMasterDataController < ListController

  # self.search_columns = []

  self.sort_mappings = {
    department: 'departments.name',
    fullname: 'fullname',
    current_percent_value: 'current_percent_value'
  }

  # before_action :authorize_action

  def show
    @employee = Employee.find(params[:id])
  end

  private

  def list_entries_without_sort
    Employee.select('employees.*, ' \
                    'employments.percent AS current_percent_value, ' \
                    'CONCAT(lastname, \' \', firstname) AS fullname')
            .employed_ones(Period.current_day)
            .includes(:department)
            .joins(current_percent_join)
            .list
  end

  def current_percent_join
    today = Time.zone.today
    'LEFT JOIN employments ON employees.id = employments.employee_id AND ' \
    "employments.start_date <= #{Employment.sanitize(today)} AND " \
    "(employments.end_date IS NULL OR employments.end_date >= #{Employment.sanitize(today)})"
  end

  def model_class
    Employee
  end

  # def authorize_action
  #   authorize!(:read, Employee)
  # end

end