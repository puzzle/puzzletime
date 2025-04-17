# frozen_string_literal: true

module Crm
  class Odoo
    class Base
      class_attribute :attributes
      class_attribute :model
      class_attribute :options
      class_attribute :parameters

      self.attributes = [].freeze
      self.parameters = [].freeze
      self.options = { fields: attributes }.freeze

      attr_reader(*attributes)

      def initialize(values = {})
        values = values.with_indifferent_access

        attributes.each do |attr|
          instance_variable_set(:"@#{attr}", values[attr])
        end
      end

      class << self
        def resources(parameters: [], options: {})
          parameters = [*self.parameters, *parameters]
          options = { **self.options, **options }

          api.search_read(
            model,
            parameters: parameters,
            options: options
          )
             .map { split_ids _1 }
        end

        def resource(id, options: {})
          options = { **self.options, **options }

          safe_to_i = proc do |val|
            val.to_i
          rescue StandardError
            -1
          end

          ids =
            Array
            .wrap(id)
            .map { safe_to_i.call(_1) }
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
          resource.each do |k, v|
            next unless /_id$/.match?(k)

            attr_name = k.split('_')[..-2].join('_')

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
