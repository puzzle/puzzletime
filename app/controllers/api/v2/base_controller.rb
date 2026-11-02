# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V2
    # Base of the Graphiti-served JSON:API under /api/v2.
    #
    # Authentication: HTTP Basic with the shared API client credentials, or the employee's Devise session.
    # Authorization: `Ability`, checked per record in ApplicationResource (writes) and ResourceController (reads);
    # which rows a user can see at all is each resource's `base_scope`.
    class BaseController < ActionController::API
      include Graphiti::Rails::Controller

      register_exception CanCan::AccessDenied, status: 403, detail: :exception,
                                               handler: Graphiti::Rails::ExceptionHandler

      before_action :require_authentication
      before_action :require_jsonapi_content_type
      before_action :set_paper_trail_whodunnit

      def current_user
        @current_user ||= authenticated_user
      end

      def current_ability
        @current_ability ||= Ability.new(current_user)
      end

      private

      def require_authentication
        render_error(401, 'Unauthorized') unless current_user
      end

      def authenticated_user
        if ActionController::HttpAuthentication::Basic.has_basic_credentials?(request)
          ApiClient.new.authenticate(*ActionController::HttpAuthentication::Basic.user_name_and_password(request))
        else
          request.env['warden'].user(:employee)
        end
      end

      # Session cookies are sent cross-site; a JSON:API content type cannot be forged by a plain form post.
      def require_jsonapi_content_type
        return if request.get? || request.delete? || request.media_type == Mime[:jsonapi].to_s

        render_error(415, "Content-Type must be #{Mime[:jsonapi]}")
      end

      def render_error(status, title)
        render json: { errors: [{ status: status.to_s, title: }] }, status:, content_type: Mime[:jsonapi]
      end
    end
  end
end
