module Invoicing
  class SmallInvoice
    class ClientSync

      class << self
        def perform
          ::Client.includes(:work_item, :contacts, :billing_addresses).find_each do |client|
            new(client, remote_keys).sync
          end
        end

        private

        def remote_keys
          @remote_keys ||= api.list(:client).each_with_object({}) do |client, hash|
            hash[client['name']] = client['id']
          end
        end
      end

      attr_reader :client, :remote_keys

      def initialize(client, remote_keys = [])
        @client = client
        @remote_keys = remote_keys
      end

      def sync
        return if client.billing_addresses.empty? # required by small invoice

        if key
          update_remote
        else
          create_remote
        end

        set_association_keys

        nil
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
        Client.new(client).to_hash
      end

      def set_association_keys
        remote = api.get(:client, key)
        set_association_key(client.billing_addresses, Address, remote['addresses'])
        set_association_key(client.contacts, Contact, remote['contacts'])
      end

      def set_association_key(list, entity, remote_list)
        list.reject(&:invoicing_key?).each do |item|
          item_data = entity.new(item).to_hash.stringify_keys
          remote_data = remote_list.find do |h|
            h = h.slice(*item_data.keys)
            h.each { |k, v| h[k] = v.to_s } # convert all values to string
            h == item_data
          end
          item.update_column(:invoicing_key, remote_data['id']) if remote_data
        end
      end

      def key
        client.invoicing_key.presence || remote_client_keys[client.name]
      end

      def api
        Invoicing.instance.api
      end
    end
  end
end
