# encoding: UTF-8
# == Schema Information
#
# Table name: clients
#
#  id           :integer          not null, primary key
#  work_item_id :integer          not null
#  crm_key      :string(255)
#  allow_local  :boolean          default(FALSE), not null
#

Fabricator(:client) do
  work_item
end
