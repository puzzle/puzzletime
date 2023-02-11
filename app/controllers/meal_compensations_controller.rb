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
                         .order('employees.firstname', 'employees.lastname')
  end

  def show
    @employee = Employee.find(params[:id])
    @worktimes = @employee.worktimes
                          .includes(:work_item)
                          .in_period(@period)
                          .where(meal_compensation: true)
  end

  def details
    @employee = Employee.find(params[:id])
    @work_item = WorkItem.find(params[:work_item])
    @worktimes = @employee.worktimes
                          .in_period(@period)
                          .where(meal_compensation: true)
                          .where(work_item: @work_item)
  end

  private

  def authorize_class
    authorize!(:meal_compensation, Evaluations::Evaluation)
  end

  def default_period
    Period.parse('-1m')
  end
end
