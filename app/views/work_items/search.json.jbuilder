# frozen_string_literal: true

json.array! @work_items do |item|
  json.id item.id
  json.name item.name
  json.path_shortnames item.path_shortnames
  json.description item.description
  json.path_names item.path_names
  json.billable item.accounting_post&.billable
  json.meal_compensation item.accounting_post&.meal_compensation
  json.work_item_id item.accounting_post&.work_item_id
  json.offered_hours AccountingPost.where(work_item_id: item.accounting_post&.work_item_id).pick(:offered_hours)
  json.done_hours AccountingPost.where(work_item_id: item.accounting_post.work_item_id).first.worktimes.sum(:hours)
  # TODO: .where(billable: true) beibehalten?
  # json.done_hours AccountingPost.where(work_item_id: item.accounting_post.work_item_id).first.worktimes.where(billable: true).sum(:hours)
end
