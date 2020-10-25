#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Invoicing
  module SmallInvoice
    # One-way sync from PuzzleTime to Small Invoice for clients, contacts and billing addresses.
    class ClientSync
      class << self
        def perform
          remote_keys = fetch_remote_keys
          ::Client.includes(:work_item, :contacts, :billing_addresses).find_each do |client|
            if client.billing_addresses.present? # required by small invoice
              begin
                new(client, remote_keys).sync
              rescue => error
                notify_sync_error(error, client)
              end
            end
          end
        end

        def fetch_remote_keys
          path = Invoicing::SmallInvoice::Entity::Contact.path
          Invoicing::SmallInvoice::Api.instance.list(path).each_with_object({}) do |client, hash|
            hash[client['number']] = client['id']
          end
        end

        def notify_sync_error(error, client = nil)
          parameters = client.present? ? record_to_params(client) : {}
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

        def record_to_params(record, prefix = 'client')
          {
            "#{prefix}_id"            => record.id,
            "#{prefix}_invoicing_key" => record.invoicing_key,
            "#{prefix}_shortname"     => record.try(:shortname),
            "#{prefix}_label"         => record.try(:label) || record.to_s,
            "#{prefix}_errors"        => record.errors.messages,
            "#{prefix}_changes"       => record.changes
          }
        end
      end

      delegate :notify_sync_error, to: 'self.class'
      attr_reader :client, :remote_keys
      class_attribute :rate_limiter
      self.rate_limiter = RateLimiter.new(Settings.small_invoice.request_rate)

      def initialize(client, remote_keys = nil)
        @client = client
        @remote_keys = remote_keys || self.class.fetch_remote_keys
      end

      def sync
        key ? update_remote : create_remote

        ContactSync.new(client).sync
        AddressSync.new(client).sync
      end

      private

      def update_remote
        if client.invoicing_key != key
          # Conflicting datasets in ptime <=> smallinvoice. We need to update the invoicing_key
          # of the client in ptime and clear the invoicing_keys of the addresses and contacts,
          # otherwise sync will abort because of conflicts.
          reset_invoicing_keys(key)
        end
        rate_limiter.run { api.edit(Entity::Contact.new(client).path, data) }
      end

      def create_remote
        # Local clients may have an invoice key that does't exist in smallinvoice (e.g. when
        # using a productive dump on ptime integration). So reset the invoicing keys before
        # executing the add action to avoid 15016 "no rights / not found" errors.
        reset_invoicing_keys

        response = rate_limiter.run { api.add(Entity::Contact.path, data) }
        client.update_column(:invoicing_key, response.fetch('id'))
        client.billing_addresses.first.update_column(:invoicing_key, response.fetch('main_address_id'))
      end

      def data
        Entity::Contact.new(client).to_hash
      end

      def fetch_remote(key)
        rate_limiter.run { api.get(Entity::Contact.path(invoicing_key: key)) }
      rescue Invoicing::Error => e
        if e.message == 'No Objects or too many found'
          reset_invoicing_keys
          nil
        else
          raise
        end
      end

      def reset_invoicing_keys(client_invoicing_key = nil)
        client.update_column(:invoicing_key, client_invoicing_key)
        client.billing_addresses.update_all(invoicing_key: nil)
        client.contacts.update_all(invoicing_key: nil)
      end

      def key
        if key_exists_remotely?
          client.invoicing_key
        else
          remote_keys[client.shortname]
        end
      end

      def key_exists_remotely?
        client.invoicing_key.present? &&
          remote_keys.values.map(&:to_s).include?(client.invoicing_key)
      end

      def api
        Api.instance
      end
    end
  end
end
