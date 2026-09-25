# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Plannings
  class CompaniesController < ApplicationController
    include WithPeriod

    self.allow_unlimited_period = false

    before_action :authorize_action
    before_action :set_period
    before_action :set_custom_list_ids

    def show
      @custom_lists = current_user.custom_lists.where(item_type: Employee.sti_name).list
      @overview = Plannings::CompanyOverview.new(@period, employee_ids: filtered_employee_ids)
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
      Period.next_n_months(3)
    end

    def set_custom_list_ids
      ids = params[:custom_list_ids] || session[:planning_custom_list_ids]
      @custom_list_ids = Array(ids).compact_blank
      session[:planning_custom_list_ids] = @custom_list_ids
    end

    def filtered_employee_ids
      return nil if @custom_list_ids.blank?

      current_user.custom_lists
                  .where(id: @custom_list_ids, item_type: Employee.sti_name)
                  .flat_map(&:item_ids)
                  .uniq
    end

    def authorize_action
      authorize!(:read, Planning)
    end
  end
end
