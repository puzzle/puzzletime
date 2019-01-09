class ApidocsController < ApplicationController
  skip_before_action :authenticate, only: [:show]
  skip_authorization_check

  layout false

  def show
    respond_to do |format|
      format.html
      format.json { render json: generate_doc }
    end
  end

  private

  def generate_doc
    Swagger::Setup.new(request.url, controller_classes).run
  end

  def controller_classes
    Rails.application.eager_load! if Rails.env.development?
    json_api_controllers
  end

  def json_api_controllers
    ListController.descendants.select { |model| model.include?(RenderJsonApi) }.select do |controller|
      controller.model_class rescue false
    end
  end

end
