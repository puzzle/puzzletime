# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  protect_from_forgery with: :exception

  before_action :authenticate
  check_authorization

  helper_method :sanitized_back_url, :current_user

  if Rails.env.production?
    rescue_from ActionController::UnknownFormat, with: :not_found
    rescue_from ActionView::MissingTemplate, with: :not_found

    rescue_from CanCan::AccessDenied do |exception|
      redirect_to root_url, alert: 'Sie sind nicht authorisiert, um diese Seite zu öffnen'
    end
  end

  private

  # Filter for check if user is logged in or not
  def authenticate
    unless current_user
      # allow ad-hoc login
      if params[:user].present? && params[:pwd].present?
        return true if login_with(params[:user], params[:pwd])
        flash[:notice] = 'Ungültige Benutzerdaten'
      end
      redirect_to controller: 'login', action: 'login', ref: request.url
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
    if p.kind_of? Array
      @period = Period.retrieve(*p)
    end
  end

  def sanitized_back_url
    uri = URI.parse(params[:back_url])
    uri.query ? "#{uri.path}?#{uri.query}" : uri.path
  end

end
