class ContactsController < ManageController

  self.nesting = [Client]

  self.permitted_attrs = [:lastname, :firstname, :function, :email, :phone, :mobile, :crm_key]

  self.search_columns = [:lastname, :firstname]

  def with_crm
    @entries = list_entries.to_a
    if Crm.instance
      existing = @entries.collect(&:crm_key).compact
      Crm.instance.find_client_contacts(parent).each do |c|
        @entries << parent.contacts.new(c) unless existing.include?(c[:crm_key])
      end
    end
  end

end
