# frozen_string_literal: true

module Apidocs
  class Setup
    attr_reader :api_version, :request_uri, :controller_classes, :swagger_spec

    MEDIA_TYPE = 'application/vnd.api+json'

    def initialize(api_version, request_url, controller_classes)
      @api_version = api_version
      @request_uri = URI.parse(request_url)
      @controller_classes = controller_classes
      @swagger_spec = Class.new do
        include Swagger::Blocks
      end
    end

    def run
      setup_metadata
      setup_controllers
      setup_models
      Swagger::Blocks.build_root_json([swagger_spec])
    end

    def host
      "#{request_uri.host}:#{request_uri.port}"
    end

    def setup_tags(swagger_doc)
      TagsSetup.new(swagger_doc).run
    end

    private

    def setup_metadata
      swagger_spec.instance_exec(self) do |helper|
        include Swagger::Blocks
        swagger_root do
          key :swagger, '2.0'
          info do
            key :version, helper.api_version
            key :title, 'Puzzletime'
            contact do
              key :name, 'Puzzletime Team'
            end
          end
          helper.setup_tags(self)
          key :host, helper.host
          key :schemes, [helper.request_uri.scheme]
          key :basePath, '/'
          key :produces, [MEDIA_TYPE]
          key :consumes, []
          security_definition 'BasicAuth' do
            key :type, 'basic'
          end
        end
      end
    end

    def setup_controllers
      controller_classes.each do |controller_class|
        ControllerSetup.new(controller_class, swagger_spec).run
        NestedControllerSetup.new(controller_classes, controller_class, swagger_spec).run
      end
    end

    def setup_models
      root_serializers = controller_classes.map(&:serializer)
      serializers = collect_serializers(*root_serializers)

      serializers.each(&method(:setup_model))
    end

    def setup_model(serializer_class)
      swagger_spec.instance_exec(self) do |helper|
        model_name = serializer_class.name.demodulize.gsub(/Serializer\z/, '').to_sym
        swagger_schema model_name do
          serializer_class.attributes_to_serialize.keys.each do |attr|
            annotation = serializer_class.attribute_annotations[attr]
            property attr do
              instance_exec(annotation, self, &helper.method(:setup_property))
            end
          end
        end
      end
    end

    def setup_property(annotation, schema_node)
      annotation.each do |name, value|
        schema_node.key(name, value)
      end
    end

    def setup_controller(controller_class)
      controller_spec = Class.new do
        include Swagger::Blocks
      end
      ControllerSetup.new(controller_class, controller_spec).run
      NestedControllerSetup.new(controller_classes, controller_class, controller_spec).run
    end

    def collect_serializers(*serializers, collected_serializers: [])
      collected_serializers += serializers

      serializers.
        map(&:relationships_to_serialize).
        compact.
        flat_map(&:values).
        map { |relationship| relationship.serializer.to_s.constantize }.
        each do |related_serializer|
          next if collected_serializers.include?(related_serializer)

          collect_serializers(related_serializer, collected_serializers:)
        end

      collected_serializers
    end
  end
end
