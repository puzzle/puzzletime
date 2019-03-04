# == Schema Information
#
# Table name: employment_roles_employments
#
#  id                       :integer          not null, primary key
#  employment_id            :integer          not null
#  employment_role_id       :integer          not null
#  employment_role_level_id :integer
#  percent                  :decimal(5, 2)    not null
#

Fabricator(:employment_roles_employment) do
  employment_role
  percent    { 1 + rand(99) }
end
