#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class Order::Controlling

  attr_reader :order, :date

  def initialize(order, date = Time.zone.now)
    @order = order
    @date = date
  end

  def offered_hours
    order.accounting_posts.sum(:offered_hours)
  end

  def hours_per_week
    {}.tap do |result|
      grouped_worktimes.each { |e| add_worktime(result, e) }
      grouped_plannings.each { |e| add_planning(result, e) }
      planning_percents_to_hours(result)
    end
  end

  private

  def planning_percents_to_hours(result)
    weeks = result.keys.sort
    return if weeks.blank?

    result_period = Period.with(weeks.first, weeks.last.end_of_week)
    WorkingCondition.each_period_of(:must_hours_per_day, result_period) do |period, must_hours|
      result
        .keys
        .select { |week| period.include?(week) }
        .each do |week|
          [:planned_definitive, :planned_provisional].each do |key|
            result[week][key] = result[week][key] / 100.0 * must_hours.to_f
          end
        end
    end
  end

  def grouped_worktimes
    load_worktimes
      .group('week, billable')
      .order('week')
      .pluck('DATE_TRUNC(\'week\', work_date) week, billable, SUM(hours)')
  end

  def grouped_plannings
    load_plannings
      .in_period(Period.with(date, nil))
      .group('week, definitive')
      .order('week')
      .pluck('DATE_TRUNC(\'week\', date) week, definitive, SUM(percent)')
  end

  def load_worktimes
    order.worktimes
  end

  def load_plannings
    Planning
      .joins(work_item: :accounting_post)
      .joins('LEFT JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)')
      .where('orders.id = ?', order.id)
  end

  def add_worktime(result, entry)
    week, billable, hours = entry
    add_value(result, week, billable ? :billable : :unbillable, hours)
  end

  def add_planning(result, entry)
    week, definitive, percent = entry
    add_value(result, week, definitive ? :planned_definitive : :planned_provisional, percent)
  end

  def add_value(result, week, key, value)
    unless result[week]
      result[week] = {
        billable: 0.0,
        unbillable: 0.0,
        planned_definitive: 0.0,
        planned_provisional: 0.0
      }
    end
    result[week][key] = value
  end


end
