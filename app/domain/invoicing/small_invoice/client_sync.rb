module Invoicing
  module SmallInvoice
    # One-way sync from PuzzleTime to Small Invoice for clients, contacts and billing addresses.
    class ClientSync
      class << self
        def perform
          remote_keys = fetch_remote_keys
          ::Client.includes(:work_item, :contacts, :billing_addresses).find_each do |client|
            if client.billing_addresses.present? # required by small invoice
              new(client, remote_keys).sync
            end
          end
        end

        def fetch_remote_keys
          SmallInvoice::Api.instance.list(:client).each_with_object({}) do |client, hash|
            hash[client['number']] = client['id']
          end
        end
      end

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
          client.billing_addresses.update_all(invoicing_key: nil)
          client.contacts.update_all(invoicing_key: nil)
          client.update_column(:invoicing_key, key)
        end
        rate_limiter.run { api.edit(:client, key, data) }
      end

      def create_remote
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
          client.update_column(:invoicing_key, nil)
          client.billing_addresses.update_all(invoicing_key: nil)
          client.contacts.update_all(invoicing_key: nil)
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
          remote_data = remote_list.find { |h| local_item == h }
          if remote_data.try(:[], 'id') && remote_data['id'].to_s != item.invoicing_key
            item.update_column(:invoicing_key, remote_data['id'])
          end
        end
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
