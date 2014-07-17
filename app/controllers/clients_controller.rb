# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class ClientsController < ManageController

  self.search_columns = [:name, :shortname]

  self.permitted_attrs = [work_item_attributes: [:name, :shortname, :description, :parent_id]]

  def categories
    item = WorkItem.find(params[:client_work_item_id])
    @categories = item.categories.list
  end

  private

  def build_entry
    client = super
    client.build_work_item
    client
  end

  def js_entry(object = entry)
    { id: object.id, label: object.to_s, work_item_id: object.work_item_id }
  end
end
