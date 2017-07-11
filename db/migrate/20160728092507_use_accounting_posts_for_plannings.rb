class UseAccountingPostsForPlannings < ActiveRecord::Migration[5.1]
  def up
    Planning.find_each do |p|
      first = p.work_item.self_and_descendants.joins(:accounting_post).list.select(:id).first
      p.update_column(:work_item_id, first.id) if first
    end
  end

  def down
    Planning.find_each do |p|
      id = p.work_item.self_and_ancestors[-2].id
      p.update_column(:work_item_id, id)
    end
  end
end
