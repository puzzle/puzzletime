#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Order::Report::BI
  attr_reader :report

  TAGS = %i[client category name status]
  TARGET_TAGS = {
    'Kosten' => :target_budget,
    'Termin' => :target_schedule,
    'Qualität' => :target_quality
  }.freeze

  METRICS = %i[
    offered_amount
    supplied_amount
    billable_amount
    billed_amount
    billability
    offered_rate
    billed_rate
    average_rate
  ]

  def initialize(departments = all_departments)
    @departments = departments
  end

  def stats
    @departments.flat_map { |d| department_stats(d) }
  end

  private

  def all_departments
    Department.having_employees
  end

  def department_stats(department)
    period = Period.new(nil, nil)
    status_ids = OrderStatus.open.pluck(:id)
    report =
      Order::Report.new(
        period,
        department_id: department.id, status_id: status_ids
      )

    targets = target_scopes

    report.entries
    report.entries.flat_map { |e| entry_stats(e, department, targets) }
  end

  def entry_stats(entry, department, targets)
    fields =
      METRICS.each_with_object({}) do |metric, memo|
        memo[metric] = entry.send(metric)
      end

    {
      name: 'order_report',
      fields: fields,
      tags: tags(entry, department, targets)
    }
  end

  def tags(entry, department, targets)
    { department: department.to_s }.merge(basic_tags(entry)).merge(
      rating_tags(entry, targets)
    )
  end

  def basic_tags(entry)
    TAGS.each_with_object({}) { |tag, memo| memo[tag] = entry.send(tag).to_s }
  end

  def rating_tags(entry, targets)
    targets.each_with_object({}) do |target, memo|
      rating = entry.target(target.id).try(:rating) || 'none'
      tag = TARGET_TAGS.fetch(target.name)
      memo[tag] = rating
    end
  end

  def target_scopes
    TargetScope.list.to_a
  end
end
