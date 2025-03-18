# frozen_string_literal: true

# Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
# PuzzleTime and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/puzzle/puzzletime.

module OrderCostsHelper
  def summed_expenses_table(entries)
    plain_table_or_message(entries) do |t|
      t.attr(:payment_date)
      t.attr(:employee_id) do |e|
        e.employee.to_s
      end
      t.attr(:amount, currency, { class: 'right' }) do |e|
        f(e.amount)
      end
      t.attr(:status_value)
      t.attr(:description)
      expense_details_col(t, personal: false)
      t.foot { summed_expenses_row(entries) }
    end
  end

  def summed_expenses_row(entries)
    content_tag(:tr, class: 'orders-cost-total_sum') do
      content_tag(:td) +
        content_tag(:td, 'Total', class: 'right') +
        content_tag(:td, f(entries.to_a.sum(&:amount)), class: 'right') +
        content_tag(:td) +
        content_tag(:td) +
        content_tag(:td)
    end
  end

  def summed_meal_compensations_table(entries)
    members = entries.select(:employee_id).distinct
    plain_table_or_message(members) do |t|
      t.attr(:employee_id) do |e|
        e.employee.to_s
      end
      days_per_member_col(t, entries)
      t.foot { summed_meal_compensations_row(entries) }
    end
  end

  def days_per_member_col(table, entries)
    table.col('Tage', class: 'right') do |e|
      employee_id_meal_compensations_days(entries)[e.employee_id].to_s
    end
  end

  def summed_meal_compensations_row(entries)
    content_tag(:tr, class: 'orders-cost-total_sum right') do
      content_tag(:td, 'Total', class: 'right') +
        content_tag(:td, f(meal_compensations_total(entries)))
    end
  end
end
