# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V2
    module Crud
      # Builds the response entity (and so the swagger schema) for a registered model from its `read` list.
      module EntityBuilder
        module_function

        # Registers the entity as `Crud::Entities::<Model>`; swagger needs a named class.
        # Registering a model again replaces its entity.
        def call(model, read)
          name = model.name.demodulize
          register(name, build(model, read, name))
        end

        def build(model, read, name)
          entity = Class.new(Grape::Entity)
          entity.define_singleton_method(:entity_name) { name } # swagger definition name
          read.each do |attr|
            if attr.is_a?(Hash)
              attr.each { |key, attrs| expose_nested(entity, model, key, attrs, name) }
            else
              entity.expose attr, documentation: doc_options(model, attr)
            end
          end
          entity
        end

        def expose_nested(entity, model, key, attrs, parent_name)
          reflection = model.reflect_on_association(key) || raise(ArgumentError, "#{model} has no association #{key}")
          nested_name = "#{parent_name}#{key.to_s.camelize}"
          nested = register(nested_name, build(reflection.klass, attrs, nested_name))
          entity.expose key, using: nested, documentation: { type: nested, is_array: reflection.collection? }
        end

        def register(name, entity)
          Entities.send(:remove_const, name) if Entities.const_defined?(name, false)
          Entities.const_set(name, entity)
        end

        # Swagger documentation for a read attribute; untyped when it is not a column.
        def doc_options(model, attr)
          column = model.columns_hash[attr.to_s] or return {}
          options = Crud.param_options(model, attr)
          type = options[:type]
          doc = type.is_a?(Array) ? { type: type.first, is_array: true } : { type: }
          # Decimals are rendered as strings (like Rails does) to keep precision.
          doc = { type: String, format: 'decimal' } if column.type == :decimal
          doc.merge(options.slice(:values), required: !column.null)
        end
      end
    end
  end
end
