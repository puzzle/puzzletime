# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Apidocs
  module Annotations
    module Serializer
      extend ActiveSupport::Concern

      # Maps ActiveRecord column types to json:api/swagger schema types.
      COLUMN_SCHEMA_TYPES = {
        integer: { type: :integer },
        string: { type: :string },
        text: { type: :string },
        boolean: { type: :boolean },
        float: { type: :number, format: :float },
        decimal: { type: :number, format: :double },
        date: { type: :string, format: :date },
        datetime: { type: :string, format: :'date-time' }
      }.freeze

      included do
        class_attribute :attribute_annotations, default: {}, instance_accessor: false
        singleton_class.send(:alias_method, :annotate_attribute, :annotate_attributes)
      end

      class_methods do
        # Annotate an attribute for the api documentation
        #
        # *attributes_list - One or more attribute names
        # **spec - The attribute specification as defined in json:api spec. See Schema Object in[1]
        #
        # [1]: https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#schema-object
        #
        def annotate_attributes(*attributes_list, **spec)
          attributes_list.each do |attr|
            attribute_annotations[attr] = spec
          end
        end

        # Whether the given attribute has an api doc annotation. Attributes
        # without one crash the doc generation, so this guards against it.
        def annotated?(attr)
          attribute_annotations.key?(attr)
        end

        # Builds an object schema from an ActiveRecord model's columns, so
        # attributes serialized via #attributes stay documented without a
        # hand-maintained property list that drifts from the schema.
        def object_schema(model)
          properties = model.columns.to_h do |column|
            [column.name.to_sym, COLUMN_SCHEMA_TYPES.fetch(column.type, { type: :string })]
          end
          { type: :object, properties: }
        end
      end
    end
  end
end
