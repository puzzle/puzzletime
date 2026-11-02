# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V2
    # The five Graphiti actions for the resource named after the controller (`DepartmentsController` serves
    # `DepartmentResource`). Subclasses are empty; restrict actions in routes.
    class ResourceController < BaseController
      def index
        authorize!(:index, resource_class.model)
        render jsonapi: resource_class.all(params)
      end

      def show
        proxy = resource_class.find(params)
        authorize!(:show, proxy.data)
        render jsonapi: proxy
      end

      def create
        proxy = resource_class.build(params)
        if proxy.save
          render jsonapi: proxy, status: :created
        else
          render jsonapi_errors: proxy
        end
      end

      def update
        proxy = resource_class.find(params)
        authorize!(:update, proxy.data)
        if proxy.update
          render jsonapi: proxy
        else
          render jsonapi_errors: proxy
        end
      end

      def destroy
        proxy = resource_class.find(params)
        if proxy.destroy
          render jsonapi: { meta: {} }, status: :ok
        else
          render jsonapi_errors: proxy
        end
      end

      private

      def resource_class
        @resource_class ||= "#{controller_name.singularize.camelize}Resource".constantize
      end
    end
  end
end
