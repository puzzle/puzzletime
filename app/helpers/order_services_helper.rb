module OrderServicesHelper

  def summed_worktimes_table(entries)
    table = checkable_worktimes_table(entries)
    if entries.present?
      footer = summed_worktimes_row(entries)
      table.gsub(/<\/tbody>\s*<\/table>/m, "</tbody><tfoot>#{footer}</tfoot></table>").html_safe
    else
      table
    end
  end

  private

  def checkable_worktimes_table(entries)
    data = {}
    if can?(:update, @order)
      data[:row_link] = edit_ordertime_path(':id', back_url: url_for(returning: true))
    end

    plain_table_or_message(entries, data: data) do |t|
      check_all = check_box_tag(:all_worktimes, true, false, data: { check: 'worktime_ids[]' })
      t.col(check_all, class: 'no-link') do |e|
        check_box_tag('worktime_ids[]', e.id)
      end
      t.attrs(:work_date, :employee_id, :hours)
      t.attr(:amount, 'CHF', class: 'right')
      t.attrs(:work_item_id, :ticket)
      t.attr(:description) { |w| w.description.to_s.truncate(40) }
      t.attrs(:billable, :invoice_id)
    end
  end

  def summed_worktimes_row(entries)
    content_tag(:tr, class: 'times_total_sum') do
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
  end

end