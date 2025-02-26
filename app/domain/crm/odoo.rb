# frozen_string_literal: true

#  Copyright (c) 2006-2025, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Crm
  class Odoo < Base
    attr_reader :api

    def initialize # ✔
      @api = Api.new
      @prefetched = {}
    end
    
    def crm_key_name = 'Odoo ID' # ✔
    def crm_key_name_plural = 'Odoo IDs' # ✔
    def name = 'Odoo' # ✔
    def icon = 'odoo.png' # ✔

    def find_order(key) # ✔
      lead = Lead.find(key.to_i)
      verify_lead_partner_type(lead)
      lead_attributes(lead)
    rescue Crm::Odoo::ResourceNotFound
      nil
    end

    def verify_lead_partner_type(lead) # ✔
      return if Company.find(lead.partner_id)
      
      partner_type =
        if lead.partner_id && Partner.find(lead.partner_id)
          :partner
        else
          :none
        end

      raise Crm::Error, I18n.t('error.crm.odoo.order_not_on_company', partner_type:)
    end

    def find_client_contacts(client) # ✔
      Company
        .partners_for(client.crm_key)
        .map { |p| contact_attributes(p) }
    end

    def find_person(key) # ✔
      partner = Partner.find(key)
      contact_attributes(partner) if partner
    end

    def find_people_by_email(email) # ✔
      Partner.all(parameters: [['email', 'ilike', email]])
    end

    def sync_all # ✔
      prefetch_resources
      sync_clients
      sync_orders
      sync_contacts
      import_client_contacts
      clear_resources
    end

    def sync_additional_order(additional) # ✔
      lead = Lead.find(additional.crm_key)
      return if additional.name == lead.name

      additional.update!(name: lead.name)
    rescue Crm::Odoo::ResourceNotFound
      additional.destroy!
    end

    def client_url(client) = crm_entity_url('contacts', client) # ✔
    def contact_url(contact) = crm_entity_url('contacts', contact) # ✔
    def order_url(order) = crm_entity_url('crm', order) # ✔
    def restrict_local? = true # ✔

    private

    def prefetch_resources
      @prefetched = {
        clients: Client.all,
        partners: Partner.all,
        leads: Lead.all
      }
    end

    def find_prefetched(group, keys)
      @prefetched[group]&.find_all { _1.id.in? Array.wrap(keys) }
    end

    def clear_resources
      @prefetched = {}
    end

    def sync_clients(ids=nil) # ✔
      context = Client.includes(:work_item)
      context = context.where(id: ids) if ids.present?

      sync_crm_entities(context) do |client|
        company = find_prefetched(:clients, client.crm_key)
        company ||= Company.find(client.crm_key)
        item = client.work_item
        return if item.name == company.name

        item.update!(name: company.name)
      end
    end

    def sync_orders(ids=nil) # ✔
      context = Order.includes(:work_item, :additional_crm_orders)
      context = context.where(id: ids) if ids.present?

      sync_crm_entities(context) do |order|
        lead = find_prefetched(:leads, order.crm_key)
        lead ||= Lead.find(order.crm_key)
        item = order.work_item

        order.additional_crm_orders.each do |additional|
          sync_additional_order(additional)
        end

        return if item.name == lead.name

        item.update!(name: lead.name)
      end
    end

    # Syncs existing contacts
    def sync_contacts(ids=nil) # ✔
      context = Contact
      context = context.where(id: ids) if ids.present?

      sync_crm_entities(context) do |contact|
        partner = find_prefetched(:partners, contact.crm_key)
        partner ||= Partner.find(contact.crm_key)
        attributes = contact_attributes(partner)

        contact.update!(attributes)
      end
    end

    # Imports missing contacts for existing clients
    def import_client_contacts(ids=nil) # ✔
      context = Client
      context = context.where(id: ids) if ids.present?

      sync_crm_entities(context) do |client|
        partners = Company.partners_for(client.crm_key)
        existing = existing_contact_crm_keys(client, partners.map(&:id))

        partners
          .reject { |p| existing.include?(p.id) }
          .each { |p| client.contacts.create(contact_attributes(p)) }
      end
    end

    def existing_contact_crm_keys(client, keys) # ✔
      client.contacts
            .where(crm_key: keys)
            .pluck(:crm_key)
            .map(&:to_i)
    end

    def lead_attributes(lead) # ✔
      {
        key: lead.id,
        name: lead.name,
        url: order_url(lead.id),
        client: {
          key: lead.partner_id,
          name: lead.partner_name
        }
      }.then { false_to_nil(_1) }
    end

    def contact_attributes(person) # ✔
      names = person.name&.split
      {
        lastname: names[1..].join(" "),
        firstname: names.first,
        function: person.function,
        email: person.email_normalized,
        phone: person.phone,
        mobile: person.mobile,
        crm_key: person.id
      }.then { false_to_nil(_1) }
    end

    def sync_crm_entities(entities) # ✔
      entities.where.not(crm_key: nil).find_each do |entity|
        yield entity
      rescue Crm::Odoo::ResourceNotFound
        entity.update_attribute(:crm_key, nil)
      rescue ActiveRecord::RecordInvalid => e
        notify_sync_error(e, entity, e.record)
      rescue StandardError => e
        notify_sync_error(e, entity)
      end
    end

    def crm_entity_url(model, entity) # ✔
      return unless key = entity.respond_to?(:crm_key)
      return if key.blank?

      "#{api.base_url}/#{model}/#{key}"
    end

    def notify_sync_error(error, synced_entity, invalid_record = nil) # ✔
      parameters = record_to_params(synced_entity, 'synced_entity').tap do |params|
        params.merge!(record_to_params(invalid_record, 'invalid_record')) if invalid_record.present?
      end
      Airbrake.notify(error, parameters) if airbrake?
      Raven.capture_exception(error, extra: parameters) if sentry?
    end

    def false_to_nil(hash)
      hash.map { |k,v| [k, v || nil] }.to_h
    end

    def airbrake? = ENV['RAILS_AIRBRAKE_HOST'].present? # ✔
    def sentry? = ENV['SENTRY_DSN'].present? # ✔

    def record_to_params(record, prefix = 'record') # ✔
      {
        "#{prefix}_type" => record.class.name,
        "#{prefix}_id" => record.id,
        "#{prefix}_label" => record.try(:label) || record.to_s,
        "#{prefix}_errors" => record.errors.messages,
        "#{prefix}_changes" => record.changes
      }
    end
  end
end
