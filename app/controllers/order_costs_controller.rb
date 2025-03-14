# frozen_string_literal: true

# Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
# PuzzleTime and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/puzzle/puzzletime.

class OrderCostsController < ApplicationController
  include MealCompensationsHelper
  def show
    authorize!(:show_costs, order)
    associated_meal_compensations
    associated_expenses
  end

  private

  def order
    @order ||= Order.find(params[:order_id])
  end

  def associated_expenses
    @associated_expenses ||= Expense.where(order_id: order.id)
                                    .includes([:employee])
  end

  def related_work_items
    WorkItem.find(order.work_item_id).self_and_descendants
  end

  def compensatable_days(employee_id, work_date)
    employee_meal_compensation_days(Employee.find(employee_id), Period.day_for(work_date))
  end

  def associated_meal_compensations
    @associated_meal_compensations ||= Worktime.where(meal_compensation: true)
                                                    .where(work_item_id: related_work_items)
                                                    .includes(%i[employee])
  end
end
