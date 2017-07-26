# encoding: utf-8

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
          SmallInvoice::Api.instance.list(:client).each_with_object({}) do |client, hash|
            hash[client['number']] = client['id']
          end
        end

        def notify_sync_error(error, client = nil)
          parameters = client.present? ? record_to_params(client) : {}
          parameters[:code] = error.code if error.respond_to?(:code)
          parameters[:data] = error.data if error.respond_to?(:data)
          Airbrake.notify(error, cgi_data: ENV.to_hash, parameters: parameters)
        end

        private

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
        if key
          update_remote
        else
          create_remote
        end

        remote = fetch_remote(client.invoicing_key)
        set_association_keys(remote) if remote
        nil
      end

      private

      def update_remote
        if client.invoicing_key != key
          # Conflicting datasets in ptime <=> smallinvoice. We need to update the invoicing_key
          # of the client in ptime and clear the invoicing_keys of the addresses and contacts,
          # otherwise sync will abort because of conflicts.
          reset_invoicing_keys(key)
        end
        rate_limiter.run { api.edit(:client, key, data) }
      end

      def create_remote
        # Local clients may have an invoice key that does't exist in smallinvoice (e.g. when
        # using a productive dump on ptime integration). So reset the invoicing keys before
        # executing the add action to avoid 15016 "no rights / not found" errors.
        reset_invoicing_keys

        key = rate_limiter.run { api.add(:client, data) }
        client.update_column(:invoicing_key, key)
      end

      def data
        Invoicing::SmallInvoice::Entity::Client.new(client).to_hash
      end

      def fetch_remote(key)
        rate_limiter.run { api.get(:client, key) }
      rescue Invoicing::Error => e
        if e.message == 'No Objects or too many found'
          reset_invoicing_keys
          nil
        else
          raise
        end
      end

      def set_association_keys(remote)
        set_association_key(Invoicing::SmallInvoice::Entity::Address,
                            client.billing_addresses,
                            remote.fetch('addresses', []))
        set_association_key(Invoicing::SmallInvoice::Entity::Contact,
                            client.contacts,
                            remote.fetch('contacts', []))
      end

      def set_association_key(entity, list, remote_list)
        list.each do |item|
          local_item = entity.new(item)
          remote_keys = remote_list.select { |h| local_item == h }.map { |h| h['id'].to_s.presence }.compact
          next if remote_keys.blank? || remote_keys.include?(item.invoicing_key)

          local_keys = list.model.where(invoicing_key: remote_keys).pluck(:invoicing_key)
          new_remote_keys = remote_keys - local_keys
          if new_remote_keys.blank?
            notify_sync_error(Invoicing::Error.new('Unable to sync from remote, ' \
                                                   'record with invoicing_key already exists',
                                                   nil,
                                                   local_item: item.id,
                                                   invoicing_keys: remote_keys,
                                                   type: entity.name))
          else
            item.update_column(:invoicing_key, new_remote_keys.first)
          end
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
