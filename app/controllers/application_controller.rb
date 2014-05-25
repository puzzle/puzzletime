# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  protect_from_forgery with: :exception

  before_action :authenticate

  private

  # Filter for check if user is logged in or not
  def authenticate
    user_id = session[:user_id]
    unless user_id
      # allow ad-hoc login
      if request.post? && params[:user] && params[:pwd]
        return true if login_with(params[:user], params[:pwd])
        flash[:notice] = 'Ungültige Benutzerdaten'
      end
      redirect_to controller: 'login', action: 'login', ref: request.url
      return false
    end
    @user = Employee.find(user_id)
    true
  end

  def authorize
    if authorized?
      true
    else
      flash[:notice] = 'Sie sind nicht authorisiert, um diese Seite zu öffnen'
      redirect_to root_path
      false
    end
  end

  def authorized?
    @user && @user.management
  end

  def managed_project?(project)
    (@user.managed_projects.collect { |p| p.id } & project.path_ids).present?
  end

  def set_period
    @period = nil
    p = session[:period]
    if p.kind_of? Array
      @period = Period.retrieve(*p)
    end
  end

  def login_with(user, pwd)
    @user = Employee.login(user, pwd)
    if @user
      reset_session
      session[:user_id] = @user.id
      true
    else
      false
    end
  end

end
