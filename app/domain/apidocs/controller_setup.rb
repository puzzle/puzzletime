# frozen_string_literal: true

module Apidocs
  class ControllerSetup
    include Rails.application.routes.url_helpers
    include Helper
    attr_reader :controller_class, :swagger_spec, :serializer

    def initialize(controller_class, swagger_spec)
      @controller_class = controller_class
      @swagger_spec = swagger_spec
      @serializer = controller_class.serializer
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
      polymorphic_path(namespace << model_name.singular_route_key, id: 1)
    rescue StandardError
      nil
    end

    def index_path
      polymorphic_path(namespace << model_name.route_key)
    rescue StandardError
      nil
    end

    private

    def namespace
      controller_class.name.sub(/(::)?\w+Controller$/, '').underscore.split('/')
    end
  end
end
