# encoding: UTF-8

# == Schema Information
#
# Table name: projects
#
#  id                    :integer          not null, primary key
#  client_id             :integer
#  name                  :string(255)      not null
#  description           :text
#  billable              :boolean          default(TRUE)
#  report_type           :string(255)      default("month")
#  description_required  :boolean          default(FALSE)
#  shortname             :string(3)        not null
#  offered_hours         :float
#  parent_id             :integer
#  department_id         :integer
#  path_ids              :integer          is an Array
#  freeze_until          :date
#  ticket_required       :boolean          default(FALSE)
#  path_shortnames       :string(255)
#  path_names            :string(2047)
#  leaf                  :boolean          default(TRUE), not null
#  inherited_description :text
#  closed                :boolean          default(FALSE), not null
#  offered_rate          :integer
#  portfolio_item_id     :integer
#  discount              :integer
#  reference             :string(255)
#


Fabricator(:project) do
  name { Faker::Company.catch_phrase }
  shortname { ('A'..'Z').to_a.shuffle.take(3).join }
  client
  department
end
