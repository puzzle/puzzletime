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
      controller_class.model_class.model_name.route_key.singularize + '_id'
    end

    def nested_model_name
      nested_class.model_class.model_name
    end

    def available_includes(controller = controller_class)
      controller.
        serializer&.
        relationships_to_serialize&.
        keys&.
        sort
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
          key :description, summary + ' Response'
          helper.response_schema(self, helper, type)
        end
      end
    end

    def setup_tags(swagger_doc)
      swagger_doc.key :tags, [
        'All',
        TagsSetup.path_tag(@path)
      ]
    end

    def parameters(swagger_doc, helper, type)
      parameter_id(swagger_doc, helper) if [:show, :nested].include?(type.to_sym)
      parameter_custom(swagger_doc, type)

      clazz = type.to_sym == :nested ? helper.nested_class : controller_class
      if available_includes(clazz).present?
        desc = include_description(clazz)
        parameter_include(swagger_doc, desc)
      end
    end

    def parameter_id(swagger_doc, helper)
      swagger_doc.parameter do
        key :name, :id
        key :in, :path
        key :description, "ID of #{helper.human_name} to fetch"
        key :required, true
        key :type, :integer
      end
    end

    def parameter_include(swagger_doc, desc)
      swagger_doc.parameter do
        key :name,        :include
        key :in,          :query
        key :description, desc
        key :required,    false
        key :type,        :string
      end
    end

    def parameter_custom(swagger_doc, type)
      controller_class.param_annotations[type].each do |param|
        swagger_doc.parameter do
          key :name,        param.name
          key :in,          :query
          key :description, param.description
          key :required,    param.required
          key :type,        param.type
          key :enum,        param.enum if param.enum.present?
        end
      end
    end

    def response_schema(swagger_doc, helper, type)
      ref = case type.to_sym
            when :index, :show then helper.model_name
            when :nested       then helper.nested_model_name
            end

      swagger_doc.schema do
        key :type, :array
        items do
          key :$ref, ref
        end
      end
    end
  end
end
