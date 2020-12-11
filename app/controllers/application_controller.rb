#  Copyright (c) 2006-2019, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  before_action :set_sentry_request_context
  protect_from_forgery with: :exception
  skip_forgery_protection if: :saml_callback_path? # HACK: https://github.com/heartcombo/devise/issues/5210

  # before_action :authenticate
  before_action :store_employee_location!, if: :storable_location?
  before_action :authenticate_employee!
  before_action :set_sentry_user_context
  before_action :set_paper_trail_whodunnit
  check_authorization unless: :devise_controller?

  helper_method :sanitized_back_url, :current_user

  if Rails.env.production?
    rescue_from ActionController::UnknownFormat, with: :not_found
    rescue_from ActionView::MissingTemplate, with: :not_found

    rescue_from CanCan::AccessDenied do |_exception|
      redirect_to root_url, alert: 'Sie sind nicht authorisiert, um diese Seite zu öffnen'
    end
  end

  def controller_module_name
    module_name = self.class.name.deconstantize.underscore.tr('/', '_')
    module_name.empty? ? 'root' : module_name
  end

  private

  def current_user
    @user ||= current_employee
  end

  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def store_employee_location!
    store_location_for(:employee, request.fullpath)
  end

  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || super
  end

  def set_period
    @period = nil
    p = session[:period]
    if p.is_a? Array
      @period = Period.new(*p)
    end
  end

  def sanitized_back_url
    uri = URI.parse(params[:back_url])
    uri.query ? "#{uri.path}?#{uri.query}" : uri.path
  end

  def not_found
    fail ActionController::RoutingError, 'Not Found'
  end

  def set_sentry_request_context
    Raven.extra_context(params: params.to_unsafe_h, url: request.url) if ENV['SENTRY_DSN']
  end

  def set_sentry_user_context
    Raven.user_context(id: current_user.try(:id), name: current_user.try(:shortname)) if ENV['SENTRY_DSN']
  end

  def saml_callback_path?
    request.fullpath == '/employees/auth/saml/callback'
  end
end
