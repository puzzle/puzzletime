# frozen_string_literal: true

module Api
  # Generates the swagger api documentation for all json:api endpoints inheriting from `Api::JsonapiController`).
  #
  # The `id` and `include` parameter are documented automatically.
  # You can add more parameters to the documentation by calling `::annotate_param` on the controller class.
  # See `Apidocs::Annotations::Controller::ClassMethods#annotate_param`
  #
  # The documentation for the json:api models is generated based on the serializer attributes and relations.
  # By default the attribute data types can not be determined from the serializer class. To improve the documentation
  # you can annotate the attributes by calling `::annotate_attribute` on the serializer class.
  # See `Apidocs::Annotations::Serializer::ClassMethods#annotate_attribute`
  #
  class ApidocsController < ApplicationController
    skip_before_action :authenticate, only: [:show]
    skip_authorization_check

    layout false

    def show
      render json: generate_doc
    end

    private

    def generate_doc
      Apidocs::Setup.new(api_version, request.url, controller_classes).run
    end

    def controller_classes
      Rails.application.eager_load! if Rails.env.development?
      ListController.descendants.select do |controller|
        controller.name.underscore.match?(%r{api/#{api_version}}) &&
          controller < Api::JsonapiController &&
          controller.model_class
      rescue NameError
        false
      end
    end

    def api_version
      params.require(:api_version)
    end
  end
end
