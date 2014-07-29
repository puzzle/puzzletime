module Crm
  class Highrise < Base

    def crm_key_label
      'Highrise ID'
    end

    def search_clients(term)
      result = ::Highrise::Company.all(from: "/companies/search.xml", params: { term: term })
      result.collect { |c| { name: c.name, crm_key: c.id } }
    end

    def recent_orders
      since = (Time.zone.now - 30.days).strftime('%Y%m%d%H%M%S')
      result = ::Highrise::Company.all(params: { status: :won, since: since })
      result.collect { |c| { name: c.name, crm_key: c.id } }
    end

    def sync_all
      sync_clients
      sync_contacts
    end

    def client_link(client)
      "#{base_url}/companies/#{client.crm_key}"
    end

    def contact_link(contact)
      "#{base_url}/people/#{contact.crm_key}"
    end

    def order_link(order)
      "#{base_url}/deals/#{order.crm_key}"
    end

    private

    def sync_clients
      Client.includes(:work_item).where('crm_key IS NOT NULL').find_each do |client|
        begin
          company = ::Highrise::Company.find(client.crm_key)
          item = client.work_item
          item.update_attributes!(name: company.name) unless item.name == company.name
        rescue ActiveResource::ResourceNotFound
          client.update_attribute(:crm_key, nil)
        end
      end
    end

    def sync_contacts
      Contact.where('crm_key IS NOT NULL').find_each do |contact|
        begin
          person = ::Highrise::Person.find(contact.crm_key)
          contact.lastname = person.last_name
          contact.firstname = person.first_name
          contact.function = person.title
          emails = person.contact_data.email_addresses
          contact.email = emails.first.address if emails.present?
          phones = person.contact_data.phone_numbers
          contact.phone = phones.find { |p| p.location == 'Work' }.try(:number)
          contact.mobile = phones.find { |p| p.location == 'Mobile' }.try(:number)
          contact.save!
        rescue ActiveResource::ResourceNotFound
          contact.update_attribute(:crm_key, nil)
        end
      end
    end

    def base_url
      Settings.highrise.url
    end
  end
end