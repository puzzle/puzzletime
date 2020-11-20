#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Invoicing
  module SmallInvoice
    # One-way sync from PuzzleTime to Small Invoice for clients, contacts and billing addresses.
    class AddressSync
      class << self
        def notify_sync_error(error, address = nil)
          parameters = address.present? ? record_to_params(address) : {}
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
        @remote_keys = remote_keys || fetch_remote_keys
      end

      def sync
        ::BillingAddress.includes(:client).where(client_id: client.id).find_each do |billing_address|
          key(billing_address) ? update_remote(billing_address) : create_remote(billing_address)
        rescue StandardError => e
          Rails.logger.error e.message
          Rails.logger.error e.backtrace
          notify_sync_error(e, billing_address)
        end
      end

      private

      def fetch_remote_keys
        api.list(Entity::Address.path(client)).map do |address|
          address['id']
        end
      end

      def update_remote(address)
        rate_limiter.run { api.edit(Entity::Address.new(address).path, data(address)) }
      end

      def create_remote(address)
        response = rate_limiter.run { api.add(Entity::Address.path(client), data(address)) }
        address.update_column(:invoicing_key, response.fetch('id'))
      end

      def data(address)
        Entity::Address.new(address).to_hash
      end

      def reset_invoicing_keys(address, invoicing_key = nil)
        address.update_column(:invoicing_key, invoicing_key)
      end

      def key(address)
        address.invoicing_key if key_exists_remotely?(address)
      end

      def key_exists_remotely?(address)
        address.invoicing_key.present? && remote_keys.map(&:to_s).include?(address.invoicing_key)
      end

      def api
        Invoicing::SmallInvoice::Api.instance
      end
    end
  end
end
