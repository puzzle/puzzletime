# frozen_string_literal: true

module Crm
  module Odoo
    class Base
      class_attribute :model
      class_attribute :parameters
      class_attribute :fields

      self.parameters = [].freeze

      delegate_missing_to :@attributes

      def initialize(attributes)
        @attributes = OpenStruct.new(attributes) # rubocop:disable Style/OpenStructUse
      end

      def self.resource(parameters: [])
        parameters = [[*self.parameters, *parameters]]
        search_read(model, parameters: parameters)
          .map { new(_1) }
      end

      def self.find(id)
        new(read(model, id))
      end
    end
  end
end
