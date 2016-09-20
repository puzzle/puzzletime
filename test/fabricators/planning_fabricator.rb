# encoding: utf-8
# == Schema Information
#
# Table name: plannings
#
#  id           :integer          not null, primary key
#  employee_id  :integer          not null
#  work_item_id :integer          not null
#  date         :date             not null
#  percent      :integer          not null
#  definitive   :boolean          default(FALSE), not null
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
