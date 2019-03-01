module Apidocs
  class NestedControllerSetup
    include Rails.application.routes.url_helpers
    include Helper

    attr_reader :controller_class, :controller_classes, :nested_class

    def initialize(controller_classes, controller_class)
      @controller_classes = controller_classes
      @controller_class = controller_class
    end

    def run
      setup_nestings
    end

    private

    def setup_nestings
      collect_nestings.each do |nested|
        @nested_class = nested
        setup_nesting
      end
    end

    def setup_nesting
      setup_swagger_path(nested_path) do |helper|
        helper.path_spec(self, helper, :nested)
      end
    end

    def nested_path
      polymorphic_path([controller_route, nested_root_path]) rescue nil
    end

    def collect_nestings
      controller_classes.collect do |controller|
        controller if nested? controller
      end.flatten.compact
    end

    def nested?(controller)
      return false if controller == controller_class

      nested = []
      #nested << controller.optional_nesting || []
      nested << controller.nesting          || []

      nested.flatten.include? controller_class.model_class
    end
  end
end