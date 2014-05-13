# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  HOME_ACTION = { controller: 'evaluator', action: 'userProjects' }

  after_action :set_charset
  filter_parameter_logging :pwd, :password

  def set_charset
    content_type = headers['Content-Type'] || 'text/html'
    if /^text\//.match(content_type)
      headers['Content-Type'] = "#{content_type}; charset=utf-8"
    end
  end

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

  def rescue_action_in_public(exception)
    case exception
      when ::ActionController::RoutingError, ActiveRecord::RecordNotFound, ::ActionController::UnknownAction
        render(file: "#{RAILS_ROOT}/public/404.html",
               status: '404 Not Found')
      else
        render(file: "#{RAILS_ROOT}/public/500.html",
               status: '500 Error')
        SystemNotifier.deliver_exception_notification(self, request, exception)
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
