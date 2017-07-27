#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Reports::Revenue
  class Base
    class_attribute :grouping_model, :grouping_fk
    delegate :grouping_name, :grouping_name_human, to: :class
    attr_reader :period, :params

    class << self
      def grouping_name
        grouping_model.sti_name
      end

      def grouping_name_human
        grouping_model.model_name.human
      end
    end

    def initialize(period, params = {})
      @period = period.extend_to_months
      @params = params
    end

    def entries
      @entries ||= directed_sort(sorted(load_entries))
    end

    def hours_without_entry?
      ordertime_hours.any? { |(entry_id, _time), _sum_hours| entry_id.nil? } ||
      planning_hours.any? { |(entry_id, _date), _sum_hours| entry_id.nil? }
    end

    def ordertime_hours
      @ordertime_hours ||= load_ordertime_hours
    end

    def total_ordertime_hours_per_month
      @total_ordertime_hours_per_month ||= load_total_ordertime_hours_per_month
    end

    def total_ordertime_hours_per_entry(entry)
      ordertime_hours
        .select { |(entry_id, _date), _hours| entry_id == entry.try(:id) }
        .values
        .sum
    end

    def average_ordertime_hours_per_entry(entry)
      hours = ordertime_hours
              .select { |(entry_id, _date), _hours| entry_id == entry.try(:id) }
              .values
      hours.empty? ? 0 : hours.sum.to_f / hours.size
    end

    def total_ordertime_hours_overall
      ordertime_hours.values.sum
    end

    def average_ordertime_hours_overall
      hours = total_ordertime_hours_per_month.values
      hours.empty? ? 0 : hours.sum.to_f / hours.size
    end

    def planning_hours
      @planning_hours ||= load_planning_hours
    end

    def total_planning_hours_per_month
      @total_planning_hours_per_month ||= load_total_planning_hours_per_month
    end

    def past_months?
      past_period.present?
    end

    def step_past_months
      @period.step_months do |date|
        yield date if date < current_month
      end
    end

    def future_months?
      future_period.present?
    end

    def step_future_months
      @period.step_months do |date|
        yield date if date >= current_month
      end
    end

    private

    def sorted(entries)
      case params[:sort]
      when 'total'
        entries.sort_by { |e| total_ordertime_hours_per_entry(e) }
      when 'average'
        entries.sort_by { |e| average_ordertime_hours_per_entry(e) }
      when /^\d{4}\-\d{2}\-\d{2}$/
        sorted_month(entries)
      else
        entries
      end
    end

    def sorted_month(entries)
      date = Date.parse(params[:sort]).beginning_of_month
      if date < current_month
        entries.sort_by { |e| ordertime_hours[[e.id, date]] || 0 }
      else
        entries.sort_by { |e| planning_hours[[e.id, date]] || 0 }
      end
    rescue ArgumentError
      entries
    end

    def directed_sort(entries)
      if params[:sort_dir].to_s.casecmp('desc') >= 0
        entries.reverse
      else
        entries
      end
    end

    def load_entries
      entry_ids = ordertime_hours
                  .merge(planning_hours)
                  .map { |(entry_id, _date), _sum| entry_id }
                  .uniq
      grouping_model.where(id: entry_ids).list
    end

    def load_ordertimes(period = past_period)
      Ordertime
        .joins(work_item: :accounting_post)
        .joins('LEFT JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)')
        .in_period(period)
        .billable
    end

    def load_plannings(period)
      Planning
        .joins(work_item: :accounting_post)
        .joins('LEFT JOIN orders ON orders.work_item_id = ANY (work_items.path_ids)')
        .in_period(period)
        .definitive
        .where(accounting_posts: { billable: true })
    end

    def load_ordertime_hours
      load_ordertimes
        .group(grouping_fk, work_date_grouping)
        .sum('hours * offered_rate')
        .each_with_object({}) do |((entry_id, time), sum_hours), result|
        result[[entry_id, time.to_date]] = sum_hours
      end
    end

    def load_total_ordertime_hours_per_month
      load_ordertimes
        .group(work_date_grouping)
        .sum('hours * offered_rate')
        .each_with_object({}) do |(time, sum_hours), result|
        result[time.to_date] = sum_hours
      end
    end

    def load_planning_hours
      load_planning_hours_each(grouping_fk, :date) do |key, sum_amount, result|
        entry_id, date = key
        date = date.beginning_of_month
        result[[entry_id, date]] ||= 0.0
        result[[entry_id, date]] += sum_amount.to_f
      end
    end

    def load_total_planning_hours_per_month
      load_planning_hours_each(:date) do |key, sum_amount, result|
        date = key.beginning_of_month
        result[date] ||= 0.0
        result[date] += sum_amount.to_f
      end
    end

    def load_planning_hours_each(*groupings)
      result = {}
      return result unless future_months?
      WorkingCondition.each_period_of(:must_hours_per_day, future_period) do |period, must_hours|
        sums = load_plannings(period)
               .group(groupings)
               .sum("percent / 100.0 * #{must_hours.to_f} * offered_rate")
        sums.each do |key, sum_amount|
          yield(key, sum_amount, result)
        end
      end
      result
    end

    def work_date_grouping
      'DATE_TRUNC(\'month\', worktimes.work_date)'
    end

    def past_period
      @past_period ||=
        if start_month >= current_month
          nil
        elsif end_month >= current_month
          Period.new(@period.start_date, (current_month - 1.month).end_of_month)
        else
          @period
        end
    end

    def future_period
      @future_period ||=
        if end_month < current_month
          nil
        elsif start_month < current_month
          Period.new(current_month, @period.end_date)
        else
          @period
        end
    end

    def start_month
      @start_month ||= @period.start_date.beginning_of_month
    end

    def end_month
      @end_month ||= @period.end_date.beginning_of_month
    end

    def current_month
      @current_month ||= Time.zone.today.beginning_of_month
    end

  end
end
