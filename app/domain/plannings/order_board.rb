# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Plannings
  class OrderBoard < Board
    alias order subject

    def row_legend(employee_id, _work_item_id)
      employees.detect { |e| e.id == employee_id }
    end

    def total_row_planned_hours(employee_id, work_item_id, only_for_active_period = false)
      period_to_calculate_hours = only_for_active_period ? @period : Period.new(nil, nil)
      @total_row_planned_hours = load_total_included_rows_planned_hours(period_to_calculate_hours)
      @total_row_planned_hours[key(employee_id, work_item_id)] || 0
    end

    def total_post_planned_hours(post)
      @total_post_planned_hours ||= load_total_posts_planned_hours
      @total_post_planned_hours[post.work_item_id] || 0
    end

    def total_plannable_hours
      accounting_posts.to_a.sum { |p| p.offered_hours.to_f }
    end

    # total planned hours on this order for all times, not limited to current period.
    def total_planned_hours(only_for_active_period = false)
      period_to_calculate_hours = only_for_active_period ? @period : Period.new(nil, nil)
      WorkingCondition.sum_with(:must_hours_per_day, period_to_calculate_hours) do |period, val|
        percent_to_hours(load_plannings(period).sum(:percent), val)
      end
    end

    def weekly_planned_hours(date)
      @weekly_planned_hours ||= Hash.new(0.0).tap do |totals|
        load_plannings.group(:date).sum(:percent).each do |d, percent|
          totals[d.at_beginning_of_week.to_date] += percent_to_hours(percent, must_hours_per_day(d))
        end
      end
      @weekly_planned_hours[date]
    end

    def included_accounting_posts
      work_item_ids = included_work_item_ids
      accounting_posts.select { |post| work_item_ids.include?(post.work_item_id) }
    end

    private

    def load_plannings(p = period)
      super
        .joins(:work_item)
        .where('? = ANY (work_items.path_ids)', order.work_item_id)
    end

    def load_accounting_posts
      order.accounting_posts
           .where(closed: false)
           .includes(:work_item)
           .list
    end

    def load_total_included_rows_planned_hours(row_period = Period.new(nil, nil))
      hours = {}
      WorkingCondition.each_period_of(:must_hours_per_day, row_period) do |period, val|
        load_plannings(period)
          .where(included_plannings_condition)
          .group(:employee_id, :work_item_id)
          .sum(:percent)
          .each do |(e, w), p|
          hours[key(e, w)] ||= 0
          hours[key(e, w)] += percent_to_hours(p, val)
        end
      end
      hours
    end

    def load_total_posts_planned_hours
      hours = {}
      WorkingCondition.each_period_of(:must_hours_per_day, Period.new(nil, nil)) do |period, val|
        load_plannings(period)
          .where(work_item_id: included_work_item_ids)
          .group(:work_item_id)
          .sum(:percent)
          .each do |w, p|
          hours[w] ||= 0
          hours[w] += percent_to_hours(p, val)
        end
      end
      hours
    end

    def percent_to_hours(percent, hours_per_day)
      percent / 100.0 * hours_per_day
    end
  end
end
