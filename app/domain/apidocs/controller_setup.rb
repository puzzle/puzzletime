module Apidocs
  class ControllerSetup
    include Rails.application.routes.url_helpers
    include Helper
    attr_reader :controller_class

    def initialize(controller_class)
      @controller_class = controller_class
    end

    def run
      setup_index_path
      setup_show_path
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
      polymorphic_path(model_name.singular_route_key, id: 1) rescue nil
    end

    def index_path
      polymorphic_path(model_name.route_key) rescue nil
    end
  end
end