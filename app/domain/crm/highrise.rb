#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Crm
  class Highrise < Base

    def crm_key_name
      'Highrise ID'
    end

    def crm_key_name_plural
      'Highrise IDs'
    end

    def name
      'Highrise'
    end

    def icon
      'highrise.png'
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
      unless deal.party.type.casecmp('company').zero?
        fail Crm::Error, I18n.t('error.crm.highrise.order_not_on_company',
                                party_type: deal.party.type)
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
      ::Highrise::Person.search(email: email)
    end

    def sync_all
      sync_clients
      sync_orders
      sync_contacts
      import_client_contacts
    end

    def sync_additional_order(additional)
      deal = ::Highrise::Deal.find(additional.crm_key)
      additional.update!(name: deal.name) unless additional.name == deal.name
    rescue ActiveResource::ResourceNotFound
      additional.destroy!
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
      sync_crm_entities(Order.includes(:work_item, :additional_crm_orders)) do |order|
        deal = ::Highrise::Deal.find(order.crm_key)
        item = order.work_item
        item.update!(name: deal.name) unless item.name == deal.name
        order.additional_crm_orders.each do |additional|
          sync_additional_order(additional)
        end
      end
    end

    # Syncs existing contacts
    def sync_contacts
      sync_crm_entities(Contact) do |contact|
        person = ::Highrise::Person.find(contact.crm_key)
        contact.update!(contact_attributes(person))
      end
    end

    # Imports missing contacts for existing clients
    def import_client_contacts
      sync_crm_entities(Client) do |client|
        people = ::Highrise::Company.new(id: client.crm_key).people
        existing = existing_contact_crm_keys(client, people.collect(&:id))
        people.reject { |p| existing.include?(p.id) }
              .each { |p| client.contacts.create(contact_attributes(p)) }
      end
    end

    def existing_contact_crm_keys(client, keys)
      client.contacts
            .where(crm_key: keys)
            .pluck(:crm_key)
            .collect(&:to_i)
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
        rescue ActiveRecord::RecordInvalid => error
          notify_sync_error(error, entity, error.record)
        rescue => error
          notify_sync_error(error, entity)
        end
      end
    end

    def crm_entity_url(model, entity)
      if entity.respond_to?(:crm_key)
        entity = entity.crm_key
      end
      "#{base_url}/#{model}/#{entity}" if entity.present?
    end

    def base_url
      Settings.highrise.url
    end

    def notify_sync_error(error, synced_entity, invalid_record = nil)
      parameters = record_to_params(synced_entity, 'synced_entity').tap do |params|
        params.merge!(record_to_params(invalid_record, 'invalid_record')) if invalid_record.present?
      end
      Airbrake.notify(error, parameters)
      Raven.capture_exception(error, extra: parameters)
    end

    def record_to_params(record, prefix = 'record')
      {
        "#{prefix}_type"    => record.class.name,
        "#{prefix}_id"      => record.id,
        "#{prefix}_label"   => record.try(:label) || record.to_s,
        "#{prefix}_errors"  => record.errors.messages,
        "#{prefix}_changes" => record.changes
      }
    end
  end
end
