# encoding: utf-8

class EmployeeAbsencesEval < Evaluation

  self.division_method  = :absences
  self.division_column  = :absence_id
  self.label            = 'Absenzen'
  self.absences         = true
  self.category_ref     = :employee_id
  self.detail_columns   = detail_columns.reject { |i| :billable == i || :booked == i }
  self.detail_labels    = detail_labels.merge(account: 'Absenz')

  def initialize(employee_id)
    super(Employee.find(employee_id))
  end

  def for?(user)
    category == user
  end

  def division_supplement(user)
    return [[:add_time_link, '']] if self.for? user
    super(user)
  end

  def employee_id
    category.id
  end

  def account_id
    division.id if division
  end

end
