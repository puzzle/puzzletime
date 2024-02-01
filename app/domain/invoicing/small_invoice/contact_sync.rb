#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Invoicing
  module SmallInvoice
    # One-way sync from PuzzleTime to Small Invoice for clients, contacts and billing addresses.
    class ContactSync
      class << self
        def notify_sync_error(error, contact = nil)
          parameters = contact.present? ? record_to_params(contact) : {}
          parameters[:code] = error.code if error.respond_to?(:code)
          parameters[:data] = error.data if error.respond_to?(:data)
          Airbrake.notify(error, parameters) if airbrake?
          Raven.capture_exception(error, extra: parameters) if sentry?
        end

        private

        def airbrake?
          ENV['RAILS_AIRBRAKE_HOST'].present?
        end

        def sentry?
          ENV['SENTRY_DSN'].present?
        end

        def record_to_params(record, prefix = 'billing_address')
          {
            "#{prefix}_id" => record.id,
            "#{prefix}_invoicing_key" => record.invoicing_key,
            "#{prefix}_shortname" => record.try(:shortname),
            "#{prefix}_label" => record.try(:label) || record.to_s,
            "#{prefix}_errors" => record.errors.messages,
            "#{prefix}_changes" => record.changes
          }
        end
      end

      delegate :notify_sync_error, to: 'self.class'
      attr_reader :client, :remote_keys

      class_attribute :rate_limiter
      self.rate_limiter = RateLimiter.new(Settings.small_invoice.request_rate)

      def initialize(client, remote_keys = nil)
        @client = client
        @remote_keys = remote_keys || fetch_remote_keys
      end

      def sync
        failed = []
        ::Contact.includes(:client).where(client_id: client.id).find_each do |contact|
          key(contact) ? update_remote(contact) : create_remote(contact)
        rescue StandardError => e
          failed << contact.id
          notify_sync_error(e, contact)
        end
        Rails.logger.error "Failed Contact Syncs: #{failed.inspect}" if failed.any?
      end

      private

      def fetch_remote_keys
        api.list(Entity::Person.path(client)).map do |person|
          person['id']
        end
      end

      def update_remote(contact)
        if contact.invoicing_key != key(contact)
          # Conflicting datasets in ptime <=> smallinvoice. We need to update the invoicing_key
          # of the client in ptime and clear the invoicing_keys of the addresses and contacts,
          # otherwise sync will abort because of conflicts.
          reset_invoicing_keys(contact, key(contact))
        end
        rate_limiter.run { api.edit(Entity::Person.new(contact).path, data(contact)) }
      end

      def create_remote(contact)
        # Local clients may have an invoice key that does't exist in smallinvoice (e.g. when
        # using a productive dump on ptime integration). So reset the invoicing keys before
        # executing the add action to avoid 15016 "no rights / not found" errors.
        reset_invoicing_keys(contact)
        response = rate_limiter.run { api.add(Entity::Person.path(client), data(contact)) }
        contact.update_column(:invoicing_key, response.fetch('id'))
      end

      def data(contact)
        Entity::Person.new(contact).to_hash
      end

      def reset_invoicing_keys(contact, invoicing_key = nil)
        contact.update_column(:invoicing_key, invoicing_key)
      end

      def key(contact)
        contact.invoicing_key if key_exists_remotely?(contact)
      end

      def key_exists_remotely?(contact)
        contact.invoicing_key.present? && remote_keys.map(&:to_s).include?(contact.invoicing_key)
      end

      def api
        Invoicing::SmallInvoice::Api.instance
      end
    end
  end
end
