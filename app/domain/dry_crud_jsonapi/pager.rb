module DryCrudJsonapi
  class Pager

    include Rails.application.routes.url_helpers
    attr_reader :scope, :model_class, :params

    delegate :current_page, :next_page, :total_pages, to: :scope

    def initialize(scope, model_class, params = {})
      @scope = scope
      @model_class = model_class
      @params = params.except(:controller, :action, :format)
    end

    def render
      [first_page, last_page, prev_page, next_page].compact.to_h
    end

    def first_page
      [:first, path(page: 1)]
    end

    def last_page
      [:last, path(page: total_pages)]
    end

    def next_page
      [:next, path(page: current_page + 1)] unless current_page >= total_pages
    end

    def prev_page
      [:prev, path(page: current_page - 1)] unless current_page <= 1
    end

    def path(params = {})
      polymorphic_path(model_class, params.merge(params))
    end
  end
end
