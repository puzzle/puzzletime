# frozen_string_literal: true

# {{{
# == Schema Information
#
# Table name: employment_roles
#
#  id                          :integer          not null, primary key
#  billable                    :boolean          not null
#  level                       :boolean          not null
#  name                        :string           not null
#  employment_role_category_id :integer
#
# Indexes
#
#  index_employment_roles_on_name  (name) UNIQUE
#
# }}}

Fabricator(:employment_role) do
  name     { sequence(:employment_role) { |i| "employment-role-#{i}" } }
  billable { false }
  level    { false }
end
