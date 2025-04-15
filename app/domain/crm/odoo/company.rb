# frozen_string_literal: true

module Crm
  class Odoo
    class Company < Base
      self.model = 'res.partner'
      self.local_models = %w[Client]
      self.attributes = %i[id name active]
      self.parameters = [['is_company', '=', true]].freeze

      class_setup

      def self.partners_for(id)
        parameters = [['parent_id', '=', id]]

        Partner.all(parameters:)
      end

      def partners
        parameters = [['parent_id', '=', id]]

        Partner.all(parameters:)
      end
    end
  end
end
