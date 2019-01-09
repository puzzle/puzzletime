Fabricator(:employment_roles_employment) do
  employment_role
  percent    { 1 + rand(99) }
end