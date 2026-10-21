# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Plannings
  class CompaniesController < ApplicationController
    include WithPeriod

    FILTERS = %i[custom_list_ids include_provisional department_id member_coach_id sort sort_dir sort_week].freeze
    SORT_KEYS = %w[name free week].freeze
    SORT_DIRS = %w[asc desc].freeze

    self.allow_unlimited_period = false

    before_action :authorize_action
    before_action :set_period
    before_action :set_filters
    before_action :set_sort

    def show
      @custom_lists = current_user.custom_lists.where(item_type: Employee.sti_name).list
      @overview = Plannings::CompanyOverview.new(@period,
                                                 employee_ids: filtered_employee_ids,
                                                 department_id: @filters[:department_id],
                                                 member_coach_id: @filters[:member_coach_id],
                                                 include_provisional: @filters[:include_provisional],
                                                 sort: @sort)
    end

    private

    def set_period
      period = build_period
      if period.nil?
        period = session[:planning_period] || default_period
      elsif period.unlimited?
        period = default_period
      end
      period = period.extend_to_weeks
      @period = session[:planning_period] = period
    end

    def default_period
      Period.next_n_months(6)
    end

    # submitted values win and are remembered in the session, otherwise the remembered ones are used
    def set_filters
      @filters = FILTERS.index_with do |name|
        key = :"planning_#{name}"
        session[key] = params[name] if params.key?(name)
        session[key]
      end
      @filters[:custom_list_ids] = Array(@filters[:custom_list_ids]).compact_blank
      @filters.transform_values!(&:presence)
      @filters[:include_provisional] = @filters[:include_provisional] == '1'
    end

    # unknown values fall back to free capacity; a week outside the period cannot be sorted by
    def set_sort
      week = sort_week_in_period
      key = @filters[:sort].presence_in(SORT_KEYS) || 'free'
      key = 'free' if key == 'week' && week.nil?
      dir = @filters[:sort_dir].presence_in(SORT_DIRS) || (key == 'name' ? 'asc' : 'desc')
      @sort = { key:, dir:, week: }
    end

    def sort_week_in_period
      week = Date.parse(@filters[:sort_week].to_s)
      mondays = []
      @period.step(7) { |date| mondays << date }
      week if mondays.include?(week)
    rescue Date::Error
      nil
    end

    def filtered_employee_ids
      return nil if @filters[:custom_list_ids].blank?

      current_user.custom_lists
                  .where(id: @filters[:custom_list_ids], item_type: Employee.sti_name)
                  .flat_map(&:item_ids)
                  .uniq
    end

    def authorize_action
      authorize!(:read, Planning)
    end
  end
end
