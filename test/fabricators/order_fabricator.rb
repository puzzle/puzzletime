Fabricator(:order) do
  work_item { Fabricate(:work_item, parent_id: Fabricate(:client).work_item_id) }
  department { Department.first }
  responsible { Employee.first }
  kind { OrderKind.list.first }
end
