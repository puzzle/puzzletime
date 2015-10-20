module Invoicing
  module SmallInvoice
    # One-way sync from PuzzleTime to Small Invoice for clients, contacts and billing addresses.
    class ClientSync
      class << self
        def perform
          ::Client.includes(:work_item, :contacts, :billing_addresses).find_each do |client|
            if client.billing_addresses.present? # required by small invoice
              new(client, remote_keys).sync
            end
          end
        end

        private

        def remote_keys
          @remote_keys ||= SmallInvoice::Api.instance.list(:client).each_with_object({}) do |client, hash|
            hash[client['name']] = client['id']
          end
        end
      end

      attr_reader :client, :remote_keys

      def initialize(client, remote_keys = {})
        @client = client
        @remote_keys = remote_keys
      end

      def sync
        if key
          update_remote # TODO: does not work "Invoicing::Error: This client number already exists"
        else
          create_remote
        end

        set_association_keys
      end

      private

      def update_remote
        client.update_column(:invoicing_key, key) unless client.invoicing_key?
        api.edit(:client, key, data)
      end

      def create_remote
        key = api.add(:client, data)
        client.update_column(:invoicing_key, key)
      end

      def data
        Invoicing::SmallInvoice::Entity::Client.new(client).to_hash
      end

      def set_association_keys
        remote = api.get(:client, key)
        set_association_key(Invoicing::SmallInvoice::Entity::Address,
                            client.billing_addresses,
                            remote['addresses'])
        set_association_key(Invoicing::SmallInvoice::Entity::Contact,
                            client.contacts,
                            remote['contacts'])
        nil
      end

      def set_association_key(entity, list, remote_list)
        list.each do |item|
          local_item = entity.new(item)
          remote_data = remote_list.find { |h| local_item == h }
          if remote_data.try(:[], 'id') && remote_data['id'] != item.invoicing_key
            item.update_column(:invoicing_key, remote_data['id'])
          end
        end
      end

      def key
        client.invoicing_key.presence || remote_keys[client.name]
      end

      def api
        Api.instance
      end
    end
  end
end
