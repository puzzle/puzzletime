module Crm
  class Highrise < Base

    def crm_key_label
      '<img src="/assets/highrise.png" width="19" height="16" /> Highrise ID'.html_safe
    end

    def find_order(key)
      deal = ::Highrise::Deal.find(key)
      {
        key: deal.id,
        name: deal.name,
        url: order_url(deal.id),
        client: {
          key: deal.party.id,
          name: deal.party.name
        }
      }
    rescue ActiveResource::ResourceNotFound
      nil
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
      sync_orders
      sync_contacts
    end

    def client_url(client)
      crm_entity_url('companies', client)
    end

    def contact_url(contact)
      crm_entity_url('people', contact)
    end

    def order_url(order)
      crm_entity_url('deals', order)
    end

    private

    def sync_clients
      sync_crm_entities(Client.includes(:work_item)) do |client|
        company = ::Highrise::Company.find(client.crm_key)
        item = client.work_item
        item.update!(name: company.name) unless item.name == company.name
      end
    end

    def sync_orders
      sync_crm_entities(Order.includes(:work_item)) do |order|
        deal = ::Highrise::Deal.find(order.crm_key)
        item = order.work_item
        item.update!(name: deal.name) unless item.name == deal.name
      end
    end

    def sync_contacts
      sync_crm_entities(Contact) do |contact|
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
      end
    end

    def sync_crm_entities(entities)
      entities.where('crm_key IS NOT NULL').find_each do |entity|
        begin
          yield entity
        rescue ActiveResource::ResourceNotFound
          entity.update_attribute(:crm_key, nil)
        end
      end
    end

    def crm_entity_url(model, entity)
      if entity.respond_to?(:crm_key)
        entity = entity.crm_key
      end
      "#{base_url}/#{model}/#{entity}"
    end

    def base_url
      Settings.highrise.url
    end
  end
end