# == Schema Information
#
# Table name: employment_roles
#
#  id                          :integer          not null, primary key
#  name                        :string           not null
#  billable?                   :boolean          not null
#  levels?                     :boolean          not null
#  employment_role_category_id :integer
#

class EmploymentRole < ActiveRecord::Base
  belongs_to :employment_role_category
end
