# frozen_string_literal: true

#  Copyright (c) 2006-2019, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  skip_forgery_protection if: -> { saml_callback_path? || authenticated_via_pat? } # HACK: https://github.com/heartcombo/devise/issues/5210

  # before_action :authenticate
  before_action :set_error_tracker_request_context
  before_action :store_employee_location!, if: :storable_location?
  before_action :authenticate_employee!
  before_action :set_error_tracker_user_context
  before_action :set_paper_trail_whodunnit
  check_authorization unless: :devise_controller?

  after_action :skip_session_cookie, if: :authenticated_via_pat?

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
    return unless p.is_a? Array

    @period = Period.new(*p) if p.is_a?(Array)
  end

  def sanitized_back_url
    uri = URI.parse(params[:back_url])
    uri.query ? "#{uri.path}?#{uri.query}" : uri.path
  end

  def not_found
    raise ActionController::RoutingError, 'Not Found'
  end

  def set_error_tracker_request_context
    commit = Settings.puzzletime.build.commit
    project = Settings.puzzletime.run.project
    customer = Settings.puzzletime.run.customer

    ErrorTracker.set_tags(commit:) if commit
    ErrorTracker.set_tags(project:) if project
    ErrorTracker.set_tags(customer:) if customer
  end

  def set_error_tracker_user_context
    ErrorTracker.set_user(
      id: current_user.try(:id),
      username: current_user.try(:shortname),
      email: current_user.try(:email)
    )
  end

  def saml_callback_path?
    request.fullpath == '/employees/auth/saml/callback'
  end

  def skip_session_cookie
    request.session_options[:skip] = true
  end

  def authenticated_via_pat?
    auth_result = request.env['warden'].authenticate(:holiday)
    auth_result.present?
  end
end
