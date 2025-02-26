# frozen_string_literal: true

module Crm
  class Odoo
    class Base
      class_attribute :model
      class_attribute :parameters
      class_attribute :options

      self.parameters = [].freeze
      self.options = {}.freeze

      attr_reader :attributes
      delegate_missing_to :@attributes

      def initialize(attributes)
        @attributes = OpenStruct.new(attributes)
      end

      class << self

        def resources(parameters: [], options: {})
          parameters = [*self.parameters, *parameters]
          options = {**self.options, **options}

          api.search_read(
            model,
            parameters: parameters,
            options: options
          )
            .map { split_ids _1 }
        end

        def resource(id, parameters: [], options: {})
          parameters = [*self.parameters, *parameters]
          options = {**self.options, **options}

          ids =
            Array.wrap(id)
            .map { _1.to_i rescue -1 }
            .select(&:positive?)

          api
            .read(model, ids, options:)
            .first
            .then { split_ids _1 }
        end

        def all(...) = resources(...).map { new _1 }
        def find(...)
          res = resource(...)
          raise ResourceNotFound unless res

          new(res)
        end

        private

        def api = Crm.instance.api

        def split_ids(resource)
          return resource unless resource

          attrs = {}
          resource.each do |k,v|
            next unless /_id$/.match?(k)
            attr_name = k.split("_")[..-2].join("_")

            if v.is_a? Array
              attrs["#{attr_name}_id"] = v.first
              attrs["#{attr_name}_name"] = v.second
            else
              attrs["#{attr_name}_name"] = v
            end
          end
          resource.merge(attrs)
        end
      end
    end
  end
end
