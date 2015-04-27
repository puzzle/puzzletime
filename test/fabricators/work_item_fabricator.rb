# == Schema Information
#
# Table name: work_items
#
#  id              :integer          not null, primary key
#  parent_id       :integer
#  name            :string(255)      not null
#  shortname       :string(5)        not null
#  description     :text
#  path_ids        :integer          is an Array
#  path_shortnames :string(255)
#  path_names      :string(2047)
#  leaf            :boolean          default(TRUE), not null
#  closed          :boolean          default(FALSE), not null
#

Fabricator(:work_item) do
  name { Faker::Company.name }
  shortname { ('A'..'Z').to_a.shuffle.take(4).join }
end
