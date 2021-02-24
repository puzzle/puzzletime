#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Order::Report::BI
  attr_reader :report

  TAGS = %i[client category name status]
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

    report.entries
    report.entries.flat_map { |e| entry_stats(e, department) }
  end

  def entry_stats(entry, department)
    tags =
      TAGS.each_with_object({}) { |tag, memo| memo[tag] = entry.send(tag).to_s }
    tags[:department] = department.to_s

    fields =
      METRICS.each_with_object({}) do |metric, memo|
        memo[metric] = entry.send(metric)
      end

    { name: 'order_report', fields: fields, tags: tags }
  end
end
