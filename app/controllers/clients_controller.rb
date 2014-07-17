# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class ClientsController < ManageController

  self.permitted_attrs = [work_item_attributes: [:name, :shortname, :description]]

  respond_to :js, only: [:new, :create]

  private

  def build_entry
    client = super
    client.build_work_item
    client
  end

  def js_entry
    { id: entry.id, label: entry.to_s, work_item_id: entry.work_item_id }
  end
end
