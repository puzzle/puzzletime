# == Schema Information
#
# Table name: employment_role_levels
#
#  id   :integer          not null, primary key
#  name :string           not null
#

class EmploymentRoleLevel < ActiveRecord::Base
  def to_s
    name
  end
end
