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
      @component_serializers = collect_serializers(*controller_classes.map(&:serializer))
      setup_metadata
      setup_controllers
      setup_components
      Swagger::Blocks.build_root_json([swagger_spec])
    end

    def host
      "#{request_uri.host}:#{request_uri.port}"
    end

    # OpenAPI 3 replaces host/schemes/basePath with a servers list.
    def server_url
      "#{request_uri.scheme}://#{host}/"
    end

    # Names of the models exposed under components/schemas, used to keep
    # `included` $refs from dangling.
    def component_schema_names
      @component_serializers.to_set { |s| s.name.demodulize.delete_suffix('Serializer') }
    end

    def setup_tags(swagger_doc)
      TagsSetup.new(swagger_doc).run
    end

    private

    def setup_metadata
      swagger_spec.instance_exec(self) do |helper|
        include Swagger::Blocks
        swagger_root do
          key :openapi, '3.0.0' # must precede info/server so the node version resolves to 3.0
          info do
            key :version, helper.api_version
            key :title, 'Puzzletime'
            contact do
              key :name, 'Puzzletime Team'
            end
          end
          helper.setup_tags(self)
          server do
            key :url, helper.server_url
          end
        end
      end
    end

    def setup_controllers
      names = component_schema_names
      controller_classes.each do |controller_class|
        ControllerSetup.new(controller_class, swagger_spec, names).run
        NestedControllerSetup.new(controller_classes, controller_class, swagger_spec, names).run
      end
    end

    # OpenAPI 3 keeps model schemas (and security schemes) under a single
    # components node; build_root_json ignores the v2 swagger_schema map. The
    # node is memoized, so every schema has to be declared in this one block.
    def setup_components
      serializers = @component_serializers
      swagger_spec.instance_exec(self) do |helper|
        swagger_component do
          security_scheme 'BasicAuth' do
            key :type, :http
            key :scheme, :basic
          end

          serializers.each do |serializer_class|
            schema serializer_class.name.demodulize.delete_suffix('Serializer').to_sym do
              # json:api resource object: attributes live under `attributes`,
              # alongside id/type — not flat at the top level.
              key :type, :object
              property(:id) { key :type, :string }
              property(:type) { key :type, :string }
              property :attributes do
                key :type, :object
                serializer_class.attributes_to_serialize.each_key do |attr|
                  raise "#{serializer_class} is missing an API doc annotation for :#{attr}" unless serializer_class.annotated?(attr)

                  annotation = serializer_class.attribute_annotations[attr]
                  property attr do
                    instance_exec(annotation, self, &helper.method(:setup_property))
                  end
                end
              end
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

    # Gathers the root serializers and every serializer reachable through their
    # relationships. Mutates the shared accumulator so transitively-related
    # serializers (e.g. a relationship of a relationship) are actually kept.
    def collect_serializers(*serializers, collected_serializers: [])
      serializers.each do |serializer|
        next if collected_serializers.include?(serializer)

        collected_serializers << serializer
        related = serializer.relationships_to_serialize&.values&.map { |r| r.serializer.to_s.constantize } || []
        collect_serializers(*related, collected_serializers:)
      end

      collected_serializers
    end
  end
end
