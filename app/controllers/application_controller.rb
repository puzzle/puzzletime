# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  HOME_ACTION = { controller: 'evaluator', action: 'userProjects' }


  # Filter for check if user is logged in or not
  def authenticate
    user_id = session[:user_id]
    unless user_id
      # allow ad-hoc login
      if request.post? && params[:user] && params[:pwd]
        return true if login_with(params[:user], params[:pwd])
        flash[:notice] = 'Ung&uuml;ltige Benutzerdaten'
      end
      redirect_to controller: 'login', action: 'login', ref: request.url
      return false
    end
    @user = Employee.find(user_id)
    true
  end

  def authorize
    if authenticate
      unless @user.management
        flash[:notice] = 'Sie sind nicht authorisiert, um diese Seite zu öffnen'
        redirect_to HOME_ACTION
        return false
      end
    else
      return false
    end
  end

  protected

  def renderGeneric(options)
    template = options[:action]
    if template && !template_exists?("#{self.class.controller_path}/#{template}")
      options[:template] = "#{genericPath}/#{template}"
    else
      options[:template] = "#{self.class.controller_path}/#{template}"
    end
    options[:action] = nil
    render options
  end

  def genericPath
    '.'
  end

  def setPeriod
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
      return true
    end
    false
  end

  private
  # TODO: delete this method after upgrading to rails 3 and use ViewPath#template_exists?
  def template_exists?(path)
    view_paths.find_template(path, response.template.template_format)
  rescue ActionView::MissingTemplate
    false
  end
end
