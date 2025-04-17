# frozen_string_literal: true

module Crm
  class Odoo
    class Partner < Base
      self.attributes = %i[id parent_id name function email_normalized phone mobile active]
      self.model = 'res.partner'
      self.local_models = %w[Contact Employee]
      self.parameters = [['is_company', '=', false]].freeze

      class_setup

      # This is sadly needed, since you can't filter on read calls
      def self.resource(...)
        result = super

        result unless result['is_company']
      end
    end
  end
end
