module DryCrudJsonapi
  extend ActiveSupport::Concern

  included do
    delegate :model_serializer, to: 'self.class'
    prepend Prepends
  end

  module Prepends
    def index
      respond_to do |format|
        format.jsonapi { jsonapi_render(entries) }
        format.all { super }
      end
    end

    def show
      respond_to do |format|
        format.jsonapi { jsonapi_render(entry) }
        format.all { super }
      end
    end
  end

  def jsonapi_pagination(resources)
    return unless action_name == 'index' && resources.present?
    DryCrudJsonapi::Pager.new(resources, model_class, params).render
  end

  def jsonapi_class
    @jsonapi_class ||= Hash.new do |hash, class_name|
      hash[class_name] = model_serializer || DryCrudJsonapi::Serializer.new(class_name).build
    end
  end

  def jsonapi_expose
    { controller: self, current_user: current_user }
  end

  def rescued_polymorphic_path(*objects)
    polymorphic_path(*objects) rescue nil
  end

  private

  def json_render_entries
    jsonapi_render(entries)
  end

  def json_render_entry
    jsonapi_render(entry)
  end

  def jsonapi_render(object)
    render jsonapi: object, include: jsonapi_include, fields: jsonapi_fields, expose: jsonapi_expose
  end

  def jsonapi_include
    params.permit(:include)[:include] || []
  end

  def jsonapi_fields
    params.permit(fields: {}).fetch('fields', []).to_h.collect do |model, string|
      [model, string.split(',')]
    end.to_h
  end

  module ClassMethods
    def model_serializer
      @model_serializer ||= "#{model_class.name}Serializer".constantize rescue nil
    end
  end

end
