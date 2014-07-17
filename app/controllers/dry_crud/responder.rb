# encoding: UTF-8

module DryCrud
  # Custom Responder that handles the controller's +path_args+.
  # An additional :success option is used to handle action callback
  # chain halts.
  class Responder < ActionController::Responder

    def initialize(controller, resources, options = {})
      super(controller, with_path_args(resources, controller), options)
    end

    def to_js
      if get? || response_overridden?
        default_render
      elsif has_errors?
        display_js_errors
      else
        controller.render text: "'#{controller.send(:js_entry).to_json}'"
      end
    rescue ActionView::MissingTemplate => e
      default_render
    end

    private

    # Check whether the resource has errors. Additionally checks the :success
    # option.
    def has_errors?
      options[:success] == false || super
    end

    # Wraps the resources with the path_args for correct nesting.
    def with_path_args(resources, controller)
      if resources.size == 1
        Array(controller.send(:path_args, resources.first))
      else
        resources
      end
    end

    def display_js_errors
      controller.render partial: 'form', status: :unprocessable_entity
    end

  end
end
