# frozen_string_literal: true

#  Copyright (c) 2006-2025, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Crm
  class Odoo < Base
    attr_reader :api

    def initialize
      super
      @api = Api.new
      @prefetched = {}
    end

    def crm_key_name = 'Odoo ID'
    def crm_key_name_plural = 'Odoo IDs'
    def name = 'Odoo'
    def icon = 'odoo.webp'
    # def icon = 'odoo.png'

    def find_order(key)
      lead = ::Crm::Odoo::Lead.find(key.to_i)
      verify_lead_partner_type(lead)
      lead_attributes(lead)
    rescue Crm::Odoo::ResourceNotFound
      nil
    end

    def verify_lead_partner_type(lead)
      return if ::Crm::Odoo::Company.find(lead.partner_id)

      partner_type =
        if lead.partner_id && ::Crm::Odoo::Partner.find(lead.partner_id)
          :partner
        else
          :none
        end

      raise Crm::Error, I18n.t('error.crm.odoo.order_not_on_company', partner_type:)
    end

    def find_client_contacts(client)
      ::Crm::Odoo::Company
        .partners_for(client.crm_key.to_i)
        .map { |p| contact_attributes(p) }
    end

    def find_person(key)
      partner = ::Crm::Odoo::Partner.find(key)
      contact_attributes(partner) if partner
    end

    def find_people_by_email(email)
      ::Crm::Odoo::Partner.all(parameters: [['email', 'ilike', email]])
    end

    def sync_all
      prefetch_resources
      sync_clients
      sync_orders
      sync_contacts
      import_client_contacts
      clear_resources
    end

    def sync_clients(ids = nil)
      context = Client.includes(:work_item)
      context = context.where(id: ids) if ids.present?

      sync_crm_entities(context) do |client|
        company = with_prefetch(:companies, client.crm_key.to_i) { ::Crm::Odoo::Company.find(_1) }
        item = client.work_item

        next if item.name == company.name

        item.update!(name: company.name)
      end
    end

    def sync_orders(ids = nil)
      context = Order.includes(:work_item, :additional_crm_orders)
      context = context.where(id: ids) if ids.present?

      sync_crm_entities(context) do |order|
        lead = with_prefetch(:leads, order.crm_key.to_i) { ::Crm::Odoo::Lead.find(_1) }
        item = order.work_item

        order.additional_crm_orders.each do |additional|
          sync_additional_order(additional)
        end

        if lead.name == 'f'
          Rails.logger.error "Refusing to change name: '#{item.name}' to 'f'"
          next
        end

        next if item.name == lead.name

        item.update!(name: lead.name)
      end
    end

    def sync_additional_order(additional)
      lead = ::Crm::Odoo::Lead.find(additional.crm_key)
      return if additional.name == lead.name

      additional.update!(name: lead.name)
    rescue Crm::Odoo::ResourceNotFound
      additional.destroy!
    end

    # Syncs existing contacts
    def sync_contacts(ids = nil)
      context = Contact
      context = context.where(id: ids) if ids.present?

      sync_crm_entities(context) do |contact|
        partner = with_prefetch(:partners, contact.crm_key.to_i) { ::Crm::Odoo::Partner.find(_1) }
        next if partner.blank?

        attributes = contact_attributes(partner)

        contact.update!(attributes)
      end
    end

    # Imports missing contacts for existing clients
    def import_client_contacts(ids = nil)
      context = Client
      context = context.where(id: ids) if ids.present?

      sync_crm_entities(context) do |client|
        partners = with_prefetch(:company_partners, client.crm_key.to_i) { ::Crm::Odoo::Company.partners_for(_1) }
        existing = existing_contact_crm_keys(client, partners.map(&:id))

        partners
          .reject { |p| existing.include?(p.id) }
          .each { |p| client.contacts.create(contact_attributes(p)) }
      end
    end

    def client_url(client) = crm_entity_url('contacts', client)
    def contact_url(contact) = crm_entity_url('contacts', contact)
    def order_url(order) = crm_entity_url('crm', order)
    def restrict_local? = true

    private

    def prefetch_resources(type = :all)
      @prefetched ||= {}

      @prefetched[:companies] = ::Crm::Odoo::Company.fetch_existing if type.in? %i[company all]
      @prefetched[:partners] = ::Crm::Odoo::Partner.fetch_existing if type.in? %i[partner all]
      @prefetched[:leads] = ::Crm::Odoo::Lead.fetch_existing if type.in? %i[lead all]
    end

    def find_prefetched(group, keys)
      if group == :company_partners
        @prefetched[:partners]&.find_all { _1.parent_id.in? Array.wrap(keys) }
      else
        @prefetched[group]&.find { _1.id.in? Array.wrap(keys) }
      end
    end

    def with_prefetch(group, keys)
      response = find_prefetched(group, keys)
      response ||= yield(keys) if block_given?

      response
    end

    def clear_resources
      @prefetched = {}
    end

    def existing_contact_crm_keys(client, keys)
      client.contacts
            .where(crm_key: keys)
            .pluck(:crm_key)
            .map(&:to_i)
    end

    def lead_attributes(lead)
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

    def contact_attributes(person)
      names = person.name&.split
      {
        lastname: names[1..].join(' '),
        firstname: names.first,
        function: person.function,
        email: person.email_normalized,
        phone: person.phone,
        mobile: person.mobile,
        crm_key: person.id
      }.then { false_to_nil(_1) }
    end

    def sync_crm_entities(entities)
      entities.where.not(crm_key: nil).find_each do |entity|
        yield entity
      rescue Crm::Odoo::ResourceNotFound
        Rails.logger.info "Could not find CRM element in Odoo:\n#{entity.pretty_inspect}"
        entity.update_attribute(:crm_key, nil)
      rescue ActiveRecord::RecordInvalid => e
        log_taken_error(e)
        notify_sync_error(e, entity, e.record)
      rescue StandardError => e
        notify_sync_error(e, entity)
      end
    end

    def crm_entity_url(model, entity)
      return unless (key = entity.respond_to?(:crm_key) && entity.crm_key.presence)

      "#{api.base_url}/#{model}/#{key}"
    end

    def notify_sync_error(error, synced_entity, invalid_record = nil)
      parameters = record_to_params(synced_entity, 'synced_entity').tap do |params|
        params.merge!(record_to_params(invalid_record, 'invalid_record')) if invalid_record.present?
      end

      Rails.logger.error <<~ERROR
        Message: #{error.message}
        Backtrace:
          #{error.backtrace.join("\n  ")}
      ERROR

      Airbrake.notify(error, parameters) if airbrake?
      Sentry.capture_exception(error, extra: parameters) if sentry?
    end

    def false_to_nil(hash)
      hash.transform_values { |v| v || nil }
    end

    def record_to_params(record, prefix = 'record')
      {
        "#{prefix}_type" => record.class.name,
        "#{prefix}_id" => record.id,
        "#{prefix}_label" => record.try(:label) || record.to_s,
        "#{prefix}_errors" => record.errors.messages,
        "#{prefix}_changes" => record.changes
      }
    end

    def log_taken_error(error)
      record = error.record
      types = record.errors.details[:name].pluck(:error)
      return unless types.include? :taken

      old_name = record.name_change[0]
      new_name = record.name_change[1]
      parent = record.parent
      conflict = parent.children.find_by(name: new_name)

      Rails.logger.error <<~ERROR
        #{record.class.name} rename failed
        From:     '#{old_name}'
        To:       '#{new_name}'
        Record:   [##{record.id}] #{record.path_shortnames}
        Parent:   [##{parent.id}] #{parent.path_shortnames}
        Conflict: [##{conflict.id}] - #{conflict.path_shortnames}
      ERROR
    end
  end
end
