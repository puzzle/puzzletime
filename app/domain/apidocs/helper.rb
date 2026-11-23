# frozen_string_literal: true

module Apidocs
  module Helper
    def setup_swagger_path(path, helper = self, &block)
      return unless path

      @path = path.gsub('/1', '/{id}')
      swagger_spec.send(:swagger_path, @path) do
        instance_exec(helper, &block)
      end
    end

    def model_name
      controller_class.model_class.model_name
    end

    def human_name
      model_name.human
    end

    def nested_human_name
      nested_model_name.human
    end

    def controller_route
      controller_class.model_class.new(id: 1)
    end

    def nested_root_path
      nested_model_name.route_key
    end

    def nested_controller_id
      "#{controller_class.model_class.model_name.route_key.singularize}_id"
    end

    def nested_model_name
      nested_class.model_class.model_name
    end

    def available_includes(controller = controller_class)
      controller
        .serializer
        .relationships_to_serialize
        .keys
        .sort
    rescue NoMethodError
      nil
    end

    # Component schema names that can appear in the top-level `included` array,
    # derived from the serializer's includable relationships and filtered to
    # those actually documented as components (so the $refs never dangle).
    def included_schema_names(controller = controller_class)
      controller
        .serializer
        .relationships_to_serialize
        .values
        .map { |relationship| relationship.record_type.to_s.camelize }
        .uniq
        .select { |name| component_schema_names.include?(name) }
        .sort
    rescue NoMethodError
      []
    end

    def include_description(controller = controller_class)
      relationships = available_includes(controller)
      'The following relationships are available: ' \
        "#{relationships.join(', ')} (separate values with a comma)"
    end

    def path_spec(swagger_doc, helper, type)
      summary =
        case type.to_sym
        when :index  then "All #{human_name.pluralize}"
        when :show   then "Single #{human_name}"
        when :nested then "All #{nested_human_name.pluralize} belonging to #{human_name}"
        end

      swagger_doc.operation :get do
        key :summary, summary
        helper.setup_tags(self)
        helper.parameters(self, helper, type)
        response 200 do
          key :description, "#{summary} Response"
          helper.response_schema(self, helper, type)
        end
      end
    end

    def setup_tags(swagger_doc)
      # Tag each operation with its controller's resource name so Swagger UI
      # groups endpoints per controller instead of one undifferentiated "All".
      swagger_doc.key :tags, [human_name]
    end

    def parameters(swagger_doc, helper, type)
      parameter_id(swagger_doc, helper) if %i[show nested].include?(type.to_sym)
      parameter_custom(swagger_doc, type)

      clazz = type.to_sym == :nested ? helper.nested_class : controller_class
      return if available_includes(clazz).blank?

      desc = include_description(clazz)
      parameter_include(swagger_doc, desc)
    end

    def parameter_id(swagger_doc, helper)
      swagger_doc.parameter do
        key :name, :id
        key :in, :path
        key :description, "ID of #{helper.human_name} to fetch"
        key :required, true
        schema { key :type, :integer }
      end
    end

    def parameter_include(swagger_doc, desc)
      swagger_doc.parameter do
        key :name,        :include
        key :in,          :query
        key :description, desc
        key :required,    false
        schema { key :type, :string }
      end
    end

    def parameter_custom(swagger_doc, type)
      controller_class.param_annotations.fetch(type, []).each do |param|
        swagger_doc.parameter do
          key :name,        param.name
          key :in,          :query
          key :description, param.description
          key :required,    param.required
          schema do
            key :type, param.type
            key :enum, param.enum if param.enum.present?
          end
        end
      end
    end

    def response_schema(swagger_doc, helper, type)
      ref = case type.to_sym
            when :index, :show then helper.model_name
            when :nested       then helper.nested_model_name
            end
      collection = type.to_sym != :show
      clazz = type.to_sym == :nested ? helper.nested_class : controller_class
      included = included_schema_names(clazz)

      swagger_doc.content(Apidocs::Setup::MEDIA_TYPE) do
        schema do
          key :type, :object
          property :data do
            if collection
              key :type, :array
              items { key :$ref, ref }
            else
              key :$ref, ref
            end
          end

          if included.present?
            property :included do
              key :type, :array
              key :description, 'Related resources requested via the `include` parameter.'
              # OpenAPI 3 `oneOf` over the includable resource schemas (those documented
              # as components); heterogeneous arrays could only be generic objects in 2.0.
              items do
                key(:oneOf, included.map { |name| { '$ref' => "#/components/schemas/#{name}" } })
              end
            end
          end
        end
      end
    end
  end
end
