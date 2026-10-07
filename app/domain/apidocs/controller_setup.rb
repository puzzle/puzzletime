# frozen_string_literal: true

module Apidocs
  class ControllerSetup
    include Rails.application.routes.url_helpers
    include Helper
    attr_reader :controller_class, :swagger_spec, :serializer, :component_schema_names

    def initialize(controller_class, swagger_spec, component_schema_names)
      @controller_class = controller_class
      @swagger_spec = swagger_spec
      @serializer = controller_class.serializer
      @component_schema_names = component_schema_names
    end

    def run
      setup_index_path if index_path
      setup_show_path if show_path
    end

    def setup_index_path
      setup_swagger_path(index_path) do |helper|
        helper.path_spec(self, helper, :index)
      end
    end

    def setup_show_path
      setup_swagger_path(show_path) do |helper|
        helper.path_spec(self, helper, :show)
      end
    end

    def show_path
      polymorphic_path(namespace << model_name.singular_route_key.to_sym, id: 1)
    rescue StandardError
      nil
    end

    def index_path
      polymorphic_path(namespace << model_name.route_key.to_sym)
    rescue StandardError
      nil
    end

    private

    # polymorphic_path requires symbols for the route parts.
    def namespace
      controller_class.name.sub(/(::)?\w+Controller$/, '').underscore.split('/').map(&:to_sym)
    end
  end
end
