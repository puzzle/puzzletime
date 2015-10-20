# encoding: utf-8
# == Schema Information
#
# Table name: plannings
#
#  id              :integer          not null, primary key
#  employee_id     :integer          not null
#  start_week      :integer          not null
#  end_week        :integer
#  definitive      :boolean          default(FALSE), not null
#  description     :text
#  monday_am       :boolean          default(FALSE), not null
#  monday_pm       :boolean          default(FALSE), not null
#  tuesday_am      :boolean          default(FALSE), not null
#  tuesday_pm      :boolean          default(FALSE), not null
#  wednesday_am    :boolean          default(FALSE), not null
#  wednesday_pm    :boolean          default(FALSE), not null
#  thursday_am     :boolean          default(FALSE), not null
#  thursday_pm     :boolean          default(FALSE), not null
#  friday_am       :boolean          default(FALSE), not null
#  friday_pm       :boolean          default(FALSE), not null
#  created_at      :datetime
#  updated_at      :datetime
#  is_abstract     :boolean
#  abstract_amount :decimal(, )
#  work_item_id    :integer          not null
#

Fabricator(:planning) do |f|
  start_week      { Time.zone.today.cweek }
  end_week        { f.start_week + 1 }
  monday_am true
  monday_pm true
  tuesday_am true
  tuesday_pm true
  wednesday_am true
  wednesday_pm true
  thursday_am true
  thursday_pm true
  friday_am true
  friday_pm true
  is_abstract false
  work_item
end
