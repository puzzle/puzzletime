# encoding: utf-8

class ClientsController < ManageController

  self.search_columns = ['work_items.name', 'work_items.shortname']

  self.permitted_attrs = [:crm_key, :allow_local, :sector_id, :e_bill_account_key,
                          work_item_attributes: [:name, :shortname, :description]]

  self.sort_mappings = { sector_id: 'sectors.name' }

  def categories
    if params[:client_work_item_id].present?
      item = WorkItem.find(params[:client_work_item_id])
      @categories = item.categories.list
    else
      @categories = []
    end
  end

  private

  def build_entry
    client = super
    client.build_work_item
    client
  end

  def list_entries
    super.includes(:sector).references(:sector)
  end

  def js_entry(object = entry)
    { id: object.id, label: object.to_s, work_item_id: object.work_item_id }
  end
end
