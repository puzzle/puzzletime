# frozen_string_literal: true

Fabricator(:employment_role) do
  name     { sequence(:employment_role) { |i| "employment-role-#{i}" } }
  billable { false }
  level    { false }
end
