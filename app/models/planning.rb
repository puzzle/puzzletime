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

class Planning < ActiveRecord::Base

  validates_by_schema
  validate :validate_planning
  validate :validate_overlappings

  belongs_to :employee
  belongs_to :work_item

  def to_s
    "für #{employee.to_s}" if employee
  end

  def start_week_date
    Week.from_integer(start_week).to_date if valid_week?(start_week)
  end

  def end_week_date
    Week.from_integer(end_week).to_date if end_week && valid_week?(end_week)
  end

  def repeat_type_no?
    end_week == start_week
  end

  def repeat_type_until?
    end_week.present? && end_week > start_week
  end

  def repeat_type_forever?
    end_week.nil?
  end

  def planned_during?(period)
    if repeat_type_forever?
      return period.end_date >= start_week_date
    end

    !((period.start_date < start_week_date && period.end_date < start_week_date) ||
      (period.start_date > end_week_date && period.end_date > end_week_date))
  end

  def monday
    monday_am && monday_pm
  end

  def tuesday
    tuesday_am && tuesday_pm
  end

  def wednesday
    wednesday_am && wednesday_pm
  end

  def thursday
    thursday_am && thursday_pm
  end

  def friday
    friday_am && friday_pm
  end

  def percent
    result = 0
    result += 10 if monday_am
    result += 10 if monday_pm
    result += 10 if tuesday_am
    result += 10 if tuesday_pm
    result += 10 if wednesday_am
    result += 10 if wednesday_pm
    result += 10 if thursday_am
    result += 10 if thursday_pm
    result += 10 if friday_am
    result += 10 if friday_pm
    result += abstract_amount
    result
  end

  def overlaps?(other_planning)
    return false if other_planning == self
    return true if self.repeat_type_forever? && other_planning.repeat_type_forever?

    # sort plannings so that p1 starts before or in same week as p2
    p1_end_week = (start_week <= other_planning.start_week) ? end_week : other_planning.end_week
    p2_start_week = (start_week <= other_planning.start_week) ? other_planning.start_week : start_week

    # set end_week to a very late date
    p1_end_week ||= 999_950

    p1_end_week >= p2_start_week
  end


  private

  def validate_planning
    errors.add(:start_week, 'Von Format ist ungültig') unless valid_week?(start_week)
    errors.add(:end_week, 'Bis Format ist ungültig') if end_week && !valid_week?(end_week)
    errors.add(:end_week, 'Bis Datum ist ungültig') if end_week && (end_week < start_week)

    if abstract_amount == 0 && !halfday_selected
      errors.add(:start_date, 'Entweder Halbtag selektieren oder Umfang auswählen (Dropdown-Box).')
    end

    if is_abstract? && abstract_amount > 0 && halfday_selected
      errors.add(:start_date, 'Abstrakte Planungen entweder mit der Selektion von Halbtagen oder durch Auswählen des Umfangs (Dropdown-Box) spezifizieren (nicht beides).')
    end

    if !is_abstract? && !halfday_selected
      errors.add(:start_date, 'Mindestens ein halber Tag muss selektiert werden')
    end
  end

  def validate_overlappings
    # todo: limit search result by date
    existing = Planning.where(work_item_id: work_item_id,
                              employee_id: employee_id,
                              is_abstract: is_abstract?)
    existing.each do |planning|
      if overlaps?(planning)
        errors.add(:start_date, "Dieses Projekt ist in diesem Zeitraum bereits #{is_abstract ? 'abstrakt' : ''} geplant")
      end
    end
  end

  def valid_week?(week)
    Week.valid?(week)
  end

  def halfday_selected
     monday_am || monday_pm ||
     tuesday_am || tuesday_pm ||
     wednesday_am || wednesday_pm ||
     thursday_am || thursday_pm ||
     friday_am || friday_pm
   end

end
