class ContactsController < ManageController

  self.nesting = [Client]

  self.permitted_attrs = [:lastname, :firstname, :function, :email, :phone, :mobile, :crm_key]

end
