#  Copyright (c) 2006-2019, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  before_action :set_sentry_request_context
  protect_from_forgery with: :exception

  before_action :authenticate
  before_action :set_sentry_user_context
  before_action :set_paper_trail_whodunnit
  check_authorization

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

  # Filter for check if user is logged in or not
  def authenticate
    case request.path
    when %r{\A/api/v\d+/}
      @user = authenticate_or_request_with_http_basic('Puzzletime') { |u, p| ApiClient.new.authenticate(u, p) }
    else
      unless current_user
        # allow ad-hoc login
        if params[:user].present? && params[:pwd].present?
          return true if login_with(params[:user], params[:pwd])

          flash[:notice] = 'Ungültige Benutzerdaten'
        end
        redirect_to login_path(ref: request.url)
      end
    end
  end

  def current_user
    @user ||= session[:user_id] && Employee.find(session[:user_id])
  end

  def login_with(user, pwd)
    @user = Employee.login(user, pwd)
    if @user
      reset_session
      session[:user_id] = @user.id
    end
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
end
