# == Schema Information
#
# Table name: orders
#
#  id                     :integer          not null, primary key
#  work_item_id           :integer          not null
#  kind_id                :integer
#  responsible_id         :integer
#  status_id              :integer
#  department_id          :integer
#  contract_id            :integer
#  billing_address_id     :integer
#  crm_key                :string
#  created_at             :datetime
#  updated_at             :datetime
#  completed_month_end_at :date
#

Fabricator(:order) do
  work_item { Fabricate(:work_item, parent_id: Fabricate(:client).work_item_id) }
  department { Department.first }
  responsible { Employee.first }
  kind { OrderKind.list.first }
end
