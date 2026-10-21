# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Demo plannings for /plannings/company: 28 weeks from the current week on (the default 6-month view spans up to 27).
# Ratios are percent of the employee's current employment.

start = Time.zone.today.beginning_of_week(:monday)
mondays = Array.new(28) { |week| start + (7 * week) }
holiday_week = 2
absence_week = 4

enclouder = WorkItem.find_by!(shortname: 'ENC')
long_item = WorkItem.seed(
  :shortname, :parent_id,
  { shortname: 'E15',
    name: 'Erweiterungen 2015 inkl. Schnittstellen-Migration, Pilotbetrieb und Schulung der Fachbereiche',
    parent_id: enclouder.id }
)[0]
AccountingPost.seed(
  :work_item_id,
  { work_item_id: long_item.id,
    portfolio_item_id: PortfolioItem.find_by!(name: 'Java EE').id,
    service_id: Service.find_by!(name: 'Software-Entwicklung').id,
    offered_hours: 300,
    offered_rate: 145,
    billable: true }
)

employee = ->(shortname) { Employee.find_by!(shortname: shortname) }
percent_of = ->(emp, ratio) { (emp.current_employment.percent.to_f * ratio.to_f / 100).round }

rows = []
plan = lambda do |emp, shortname, definitive: true, &ratio|
  work_item_id = WorkItem.find_by!(shortname: shortname).id
  mondays.each_with_index do |monday, week|
    next if week == holiday_week

    percent = percent_of.call(emp, ratio.call(week))
    next if percent.zero?

    (0..4).each do |day|
      rows << { employee_id: emp.id, work_item_id: work_item_id, date: monday + day,
                percent: percent, definitive: definitive }
    end
  end
end

mw, ar, pz, bs, di, tbu, az = %w[MW AR PZ BS DI TBU AZ].map { |short| employee.call(short) }

# MW: definitive, covers every heatmap bin incl. over-planned
plan.call(mw, 'OPF') { |week| [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110][week % 12] }

# AR: definitive, over and under
plan.call(ar, 'ERP') { |week| [60, 80, 100, 120, 40, 20][week % 6] }

# PZ: definitive on three posts, one with a long label
pz_ratio = ->(week) { [50, 70, 90, 30, 110, 10][week % 6] }
plan.call(pz, 'E15') { |week| pz_ratio.call(week) * 0.5 }
plan.call(pz, 'OPF') { |week| pz_ratio.call(week) * 0.3 }
plan.call(pz, 'E14') { |week| pz_ratio.call(week) * 0.2 }

# BS: definitive, ramps up, unplanned weeks 13-15
plan.call(bs, 'DIS') do |week|
  week.between?(13, 15) ? 0 : [10, 20, 30, 40, 50, 60, 70, 80, 90, 100][week % 10]
end

# DI: only provisional plannings, so the default view shows 0
plan.call(di, 'E14', definitive: false) { |week| [50, 100, 70, 30, 90, 10][week % 6] }

# TBU: definitive, 0 in week 4 where he has an absence
plan.call(tbu, 'OPF') { |week| [40, 60, 80, 20, 0, 90][week % 6] }

# AZ: definitive and provisional on the same weeks
plan.call(az, 'OPF') { |week| [30, 50, 70, 20, 60, 40][week % 6] }
plan.call(az, 'E14', definitive: false) { |week| [10, 20][week % 2] }

# AM and PSI: no plannings

Planning.seed(:employee_id, :work_item_id, :date, *rows)

ferien = Absence.find_by!(name: 'Ferien')
absences = (0..2).map do |day|
  date = mondays[absence_week] + day
  { employee_id: tbu.id,
    absence_id: ferien.id,
    report_type: 'absolute_day',
    work_date: date,
    hours: WorkingCondition.value_at(date, :must_hours_per_day) }
end
Absencetime.seed(:employee_id, :work_date, *absences)

Holiday.seed(:holiday_date, { holiday_date: mondays[holiday_week] + 2, musthours_day: 0 })

lists = Employee.where(management: true).flat_map do |manager|
  [{ employee_id: manager.id, name: 'Team Ruby', item_type: 'Employee',
     item_ids: Employee.where(shortname: %w[PZ BS AZ]).ids },
   { employee_id: manager.id, name: 'Team Ops', item_type: 'Employee',
     item_ids: Employee.where(shortname: %w[BS AZ TBU AM]).ids }]
end
CustomList.seed(:employee_id, :name, *lists)
