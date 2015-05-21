module Crm
  class Highrise < Base

    include ActionView::Helpers::AssetUrlHelper

    def crm_key_label
      src = ActionController::Base.helpers.image_path("highrise.png")
      "<img src=\"#{src}\" width=\"19\" height=\"16\" /> #{crm_key_name}".html_safe
    end

    def crm_key_name
      'Highrise ID'
    end

    def find_order(key)
      deal = ::Highrise::Deal.find(key)
      verify_deal_party_type(deal)
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

    def verify_deal_party_type(deal)
      unless deal.party.type.downcase == 'company'
        raise Crm::Error.new(I18n.t('error.crm.highrise.order_not_on_company', party_type: deal.party.type))
      end
    end

    def find_client_contacts(client)
      company = ::Highrise::Company.new(id: client.crm_key)
      company.people.collect { |p| contact_attributes(p) }
    end

    def find_person(key)
      person = ::Highrise::Person.find(key)
      contact_attributes(person) if person
    end

    def find_people_by_email(email)
      # TODO: test
      ::Highrise::Person.search(email: email)
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

    def restrict_local?
      true
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
        contact.update!(contact_attributes(person))
      end
    end

    def contact_attributes(person)
      emails = person.contact_data.email_addresses
      phones = person.contact_data.phone_numbers
      { lastname: person.last_name,
        firstname: person.first_name,
        function: person.title,
        email: emails.first.try(:address),
        phone: phones.find { |p| p.location == 'Work' }.try(:number),
        mobile: phones.find { |p| p.location == 'Mobile' }.try(:number),
        crm_key: person.id }
    end

    def sync_crm_entities(entities)
      entities.where('crm_key IS NOT NULL').find_each do |entity|
        begin
          yield entity
        rescue ActiveResource::ResourceNotFound
          entity.update_attribute(:crm_key, nil)
        rescue => ex
          Airbrake.notify(ex)
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
