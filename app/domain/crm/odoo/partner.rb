# frozen_string_literal: true

module Crm
  class Odoo
    class Partner < Base
      self.model = 'res.partner'
      self.parameters = [['is_company', '=', false]].freeze

      # This is sadly needed, since you can't filter on read calls
      def self.resource(...)
        result = super(...)

       return result unless result["is_company"]
      end
    end
  end
end
