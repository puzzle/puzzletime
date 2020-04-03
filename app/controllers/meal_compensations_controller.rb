#  Copyright (c) 2006-2020, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class MealCompensationsController < ApplicationController
  include WithPeriod

  before_action :authorize_class
  before_action :set_period

  def index
    @worktimes = Worktime.includes(:employee)
                         .in_period(@period)
                         .where(meal_compensation: true)
  end

  def show
    @employee = Employee.find(params[:id])
    @worktimes = @employee.worktimes
                          .includes(:work_item)
                          .in_period(@period)
                          .where(meal_compensation: true)
  end

  private

  def authorize_class
    authorize!(:meal_compensation, Evaluation)
  end

  def default_period
    Period.parse('-1m')
  end
end
