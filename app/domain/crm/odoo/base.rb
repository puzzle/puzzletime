# frozen_string_literal: true

module Crm
  class Odoo
    class Base
      class_attribute :attributes
      class_attribute :local_models
      class_attribute :model
      class_attribute :optional_attributes
      class_attribute :options
      class_attribute :parameters

      self.attributes = [].freeze
      self.optional_attributes = [].freeze
      self.parameters = [].freeze
      self.options = {}.freeze

      def initialize(values = {})
        values = values.with_indifferent_access

        attributes.each do |attr|
          instance_variable_set(:"@#{attr}", values[attr])
        end

        # Only set when the Odoo version returned the field, see #attribute?
        optional_attributes.each do |attr|
          instance_variable_set(:"@#{attr}", values[attr]) if values.key?(attr)
        end
      end

      def attribute?(attr) = instance_variable_defined?(:"@#{attr}")

      class << self
        def class_setup
          attr_reader(*attributes, *optional_attributes) if attributes.present?
          self.options = { fields: attributes }.freeze if options.blank?
        end

        def resources(parameters: [], options: {})
          parameters = [*self.parameters, *parameters]
          options = request_options(options)

          api.search_read(model, parameters:, options:)
             .map do |resource|
               resource
                 .then { split_ids(_1) }
                 .tap { log_resource(_1) }
             end
        end

        def resource(id, options: {})
          options = request_options(options)

          ids =
            Array
            .wrap(id)
            .map { safe_to_i(_1) }
            .select(&:positive?)

          return if ids.empty?

          api
            .read(model, ids, options:)
            .first
            .then { split_ids(_1) }
            .tap { log_resource(_1) }
        end

        def all(...) = resources(...).map { new(_1) }

        def find(...)
          res = resource(...)
          raise ResourceNotFound unless res

          new(res)
        end

        def fetch_existing(options: {})
          options = request_options(options)

          ids =
            local_models.flat_map do |local_model|
              local_model
                .classify
                .constantize
                .where.not(crm_key: nil)
                .pluck(:crm_key)
                .map { safe_to_i(_1) }
            end

          return if ids.empty?

          api.read(model, ids, options:)
             .map do |resource|
               resource
                 .then { split_ids(_1) }
                 .tap { log_resource(_1) }
                 .then { new(_1) }
             end
        end

        private

        def api = Crm.instance.api

        # Optional fields are only requested when this Odoo version has them
        # (e.g. res.partner#mobile was removed in Odoo 19).
        # ponytail: memoized for the process lifetime, restart after an Odoo upgrade.
        def request_options(options)
          options = { **self.options, **options }
          return options if optional_attributes.blank?

          @available_optional_attributes ||=
            optional_attributes & api.fields_get(model, options: { attributes: %w[type] }).keys.map(&:to_sym)
          options.merge(fields: [*options[:fields], *@available_optional_attributes])
        end

        def safe_to_i(val)
          val.to_i
        rescue StandardError
          -1
        end

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

        def log_resource(resource)
          if resource.present? && resource['name'] == 'f'
            Rails.logger.warn "Odoo Resource with name 'f' found: #{resource.pretty_inspect}"
          elsif Settings.odoo.log_resources
            Rails.logger.info "Odoo Resource: #{resource.pretty_inspect}"
          end
        end
      end
    end
  end
end
