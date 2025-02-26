# frozen_string_literal: true

module Crm
  class Odoo
    class Company < Base
      self.model = 'res.partner'
      self.parameters = [['is_company', '=', true]].freeze
      self.options = {fields: %i[id name]}.freeze

      def self.partners_for(id)
        find(id).partners
      end

      def partners
        parameters = [['parent_id', '=', id]]

        Partner.all(parameters:)
      end
    end
  end
end
