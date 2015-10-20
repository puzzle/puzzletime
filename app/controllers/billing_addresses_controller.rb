class BillingAddressesController < ManageController
  self.nesting = [Client]

  self.permitted_attrs = [:contact_id, :supplement, :street, :zip_code, :town, :country]

  before_render_form :set_contacts

  private

  def set_contacts
    @contacts = parent.contacts.list
  end
end
