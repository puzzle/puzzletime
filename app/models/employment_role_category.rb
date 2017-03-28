# == Schema Information
#
# Table name: employment_role_categories
#
#  id   :integer          not null, primary key
#  name :string           not null
#

class EmploymentRoleCategory < ActiveRecord::Base
  has_many :employment_roles, dependent: :restrict_with_exception

  def to_s
    name
  end
end
