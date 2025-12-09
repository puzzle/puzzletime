# frozen_string_literal: true

# {{{
# == Schema Information
#
# Table name: employment_roles_employments
#
#  id                       :integer          not null, primary key
#  percent                  :decimal(5, 2)    not null
#  employment_id            :integer          not null
#  employment_role_id       :integer          not null
#  employment_role_level_id :integer
#
# Indexes
#
#  index_unique_employment_employment_role  (employment_id,employment_role_id) UNIQUE
#
# }}}

Fabricator(:employment_roles_employment) do
  employment_role
  percent { rand(1..99) }
end
