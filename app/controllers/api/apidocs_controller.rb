module Api
  class ApidocsController < ApplicationController
    skip_before_action :authenticate, only: [:show]
    skip_authorization_check

    layout false

    def show
      render json: generate_doc
    end

    private

    def generate_doc
      binding.pry
      Apidocs::Setup.new(request.url, controller_classes).run
    end

    def controller_classes
      Rails.application.eager_load! if Rails.env.development?
      json_api_controllers
    end

    def json_api_controllers
      ListController.descendants.select do |controller|
        controller.instance_methods.include?(:serializer) && controller.model_class
      end
    end
  end
end