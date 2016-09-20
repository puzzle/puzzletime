# == Schema Information
#
# Table name: order_team_members
#
#  false       :integer          not null, primary key
#  employee_id :integer          not null
#  order_id    :integer          not null
#  comment     :string
#

class OrderTeamMember < ActiveRecord::Base
  belongs_to :employee
  belongs_to :order

  validates_by_schema

  scope :list, -> do
    includes(:employee).references(:employee).order('employees.lastname, employees.firstname')
  end

  def to_s
    [employee, comment.presence].compact.join(': ')
  end
end
