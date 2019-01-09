module Swagger
  class Setup
    attr_reader :request_uri, :controller_classes

    def initialize(request_url, controller_classes)
      @request_uri = URI.parse(request_url)
      @controller_classes = controller_classes
    end

    def run
      swaggered_classes = [setup_metadata, setup_controllers, setup_models].flatten
      Swagger::Blocks.build_root_json(swaggered_classes)
    end

    def host
      "#{request_uri.host}:#{request_uri.port}"
    end

    def json_api_mimetype
      JSONAPI::Rails::Railtie::MEDIA_TYPE
    end

    def setup_tags(swagger_doc)
      Swagger::TagsSetup.new(swagger_doc).run
    end

    private

    def setup_metadata # rubocop:disable Metrics/MethodLength
      ApidocsController.instance_exec(self) do |helper|
        include Swagger::Blocks
        swagger_root do
          key :swagger, '2.0'
          info do
            key :version, Puzzletime.version
            key :title, 'Puzzletime'
            contact do
              key :name, 'Puzzletime Team'
            end
          end
          helper.setup_tags(self)
          key :host, helper.host
          key :schemes, [helper.request_uri.scheme]
          key :basePath, '/'
          key :produces, [helper.json_api_mimetype]
          key :consumes, [helper.json_api_mimetype]
          security_definition 'BasicAuth' do
            key :type, 'basic'
          end
        end
      end
      ApidocsController
    end

    def setup_controllers
      controller_classes.each(&method(:setup_controller))
      controller_classes
    end

    def setup_models
      exposed_models.each(&method(:setup_model))
      exposed_models
    end

    def exposed_models
      root_models = controller_classes.map(&:model_class)
      (root_models + root_models.map(&:reflect_on_all_associations).flatten.map(&:klass)).uniq
    end

    def setup_model(model_class)
      model_class.instance_exec(self) do |_helper|
        include Swagger::Blocks
        swagger_schema model_class.name.to_sym do
          model_class.columns.each do |column|
            property column.name do
              case column.type
              when :float
                key :type, 'number'
              when :date
                key :type, 'string'
                key :format, 'date'
              when :time
                key :type, 'string'
                key :format, 'date-time'
              else
                key :type, column.type
              end
            end
          end
        end
      end
    end

    def setup_controller(controller_class)
      controller_class.send :include, Swagger::Blocks
      Swagger::ControllerSetup.new(controller_class).run
      Swagger::NestedControllerSetup.new(controller_classes, controller_class).run
    end

  end

end
