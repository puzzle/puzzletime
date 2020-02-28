#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module OrderServicesHelper
  def summed_worktimes_table(entries, options = {})
    options[:footer] = checkable_worktimes_footer(entries)
    checkable_worktimes_table(entries, options)
  end

  private

  def checkable_worktimes_table(entries, options)
    plain_table_or_message(entries, data: checkable_worktimes_data) do |t|
      t.row_attrs { |e| { data: { no_link: cannot?(:update, e) } } }
      worktimes_checkbox_column(t, options)
      t.attr(:work_date)
      t.attr(:employee_id) do |e|
        e.employee.to_s
      end
      t.attr(:hours)
      t.attr(:amount, currency, class: 'right')
      t.attr(:work_item_id) do |e|
        e.work_item.to_s
      end
      t.attr(:ticket)
      t.attr(:description, nil, class: 'truncated', style: 'max-width: 250px;') do |w|
        content_tag(:span, w.description.to_s, title: w.description)
      end
      t.attrs(:billable, :meal_compensation, :invoice_id)
      t.foot { options[:footer] } if options[:footer]
    end
  end

  def checkable_worktimes_data
    data = {}
    if can?(:update, @order)
      data[:row_link] = edit_ordertime_path(':id', back_url: url_for(returning: true))
    end
    data
  end

  def checkable_worktimes_footer(entries)
    if entries.present?
      footer = summed_worktimes_row(entries)
      if entries.size == OrderServicesController::MAX_ENTRIES
        too_many_entries_row + footer
      else
        footer
      end
    end
  end

  def worktimes_checkbox_column(t, options)
    check_all = check_box_tag(:all_worktimes, true, false, data: { check: 'worktime_ids[]' })
    t.col(check_all, class: 'no-link') do |e|
      required_perm = options[:checkbox_requires_permission]
      if required_perm.nil? || can?(required_perm, e)
        check_box_tag('worktime_ids[]', e.id)
      end
    end
  end

  def summed_worktimes_row(entries)
    content_tag(:tr, class: 'times_total_sum') do
      summed_worktimes_cells(entries)
    end
  end

  def summed_worktimes_cells(entries)
    content_tag(:td) +
        content_tag(:td, 'Total') +
        content_tag(:td) +
        content_tag(:td, f(entries.to_a.sum(&:hours)), class: 'right') +
        content_tag(:td, f(entries.to_a.sum(&:amount)), class: 'right') +
        content_tag(:td) +
        content_tag(:td) +
        content_tag(:td) +
        content_tag(:td) +
        content_tag(:td)
  end

  def too_many_entries_row
    content_tag(:tr, class: 'center') do
      content_tag(:td, 'Weitere Einträge werden nicht angezeigt. Bitte passen Sie die Filterkriterien an, um die ' \
                       'Anzahl Einträge zu reduzieren.', colspan: 10)
    end
  end
end
