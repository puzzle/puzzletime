# == Schema Information
#
# Table name: employment_role_levels
#
#  id   :integer          not null, primary key
#  name :string           not null
#

class EmploymentRoleLevel < ActiveRecord::Base
  has_many :employment_roles_employments, dependent: :restrict_with_exception

  def to_s
    name
  end
end
