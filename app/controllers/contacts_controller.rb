class ContactsController < ManageController

  self.nesting = [Client]

  self.permitted_attrs = [:lastname, :firstname, :function, :email, :phone, :mobile, :crm_key]

  def with_crm
    @client = Client.find_by_work_item_id!(params[:client_work_item_id])
    @entries = @client.contacts.list.to_a
    if Crm.instance
      existing = @entries.collect(&:crm_key).compact
      Crm.instance.find_client_contacts(@client).each do |c|
        @entries << @client.contacts.new(c) unless existing.include?(c[:crm_key].to_s)
      end
    end
  end

end
