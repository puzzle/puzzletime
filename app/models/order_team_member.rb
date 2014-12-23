class OrderTeamMember < ActiveRecord::Base
  belongs_to :employee
  belongs_to :order

  scope :list, -> do
    includes(:employee).references(:employee).order('employees.lastname, employees.firstname')
  end

  def to_s
    [employee, comment.presence].compact.join(': ')
  end

end
