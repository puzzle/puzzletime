# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module ProgressBarHelper
  # returns the percentage of the budget that is already used, defaulting to 0 for orders with no budget
  def get_order_budget_used_percentage(order)
    order_progress(order)[:percent_title] || 0
  end

  def order_progress_bar(order)
    progress = order_progress(order)

    order_progress_bar_link(order.order, progress) do
      ''.html_safe.tap do |content|
        if progress[:percent].positive?
          content << content_tag(
            :div,
            nil,
            class: 'progress-bar progress-bar-success',
            style: "width:#{f(progress[:percent])}%"
          )
        end

        if progress[:over_budget_percent].positive?
          content << content_tag(
            :div,
            nil,
            class: 'progress-bar progress-bar-danger',
            style: "width:#{f(progress[:over_budget_percent])}%"
          )
        end
      end
    end
  end

  private

  def order_progress_bar_link(order, progress, &)
    title = "#{f(progress[:percent_title] || 0)}% geleistet"

    if can?(:show, order)
      link_to(order_order_controlling_url(order.id),
              { class: 'progress', title: },
              &)
    else
      content_tag(:div, yield, class: 'progress', title:)
    end
  end

  def order_progress(order)
    progress = order_progress_hash
    return progress unless order.offered_amount.positive?

    calculate_order_progress(order, progress)
    progress
  end

  def order_progress_hash
    {
      percent: 0,
      over_budget_percent: 0
    }
  end

  def calculate_order_progress(order, progress)
    progress[:percent] = 100 /
                         order.offered_amount.to_f *
                         order.supplied_amount.to_f
    progress[:percent_title] = progress[:percent]

    return unless order.supplied_amount.to_f > order.offered_amount.to_f

    progress[:over_budget_percent] =
      (order.supplied_amount.to_f - order.offered_amount.to_f) /
      order.supplied_amount.to_f *
      100
    progress[:percent] = (100 - progress[:over_budget_percent])
  end
end
