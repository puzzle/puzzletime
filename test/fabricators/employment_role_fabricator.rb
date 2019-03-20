# frozen_string_literal: true

# == Schema Information
#
# Table name: employment_roles
#
#  id                          :integer          not null, primary key
#  name                        :string           not null
#  billable                    :boolean          not null
#  level                       :boolean          not null
#  employment_role_category_id :integer
#


Fabricator(:employment_role) do
  name     { sequence(:employment_role) { |i| "employment-role-#{i}" } }
  billable { false }
  level    { false }
end
