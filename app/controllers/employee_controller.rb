# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class EmployeeController < ManageController

  # Checks if employee came from login or from direct url
  before_filter :authorize, :except => [:changePasswd, :updatePwd, :settings, :save_settings]
  before_filter :authenticate, :only => [:changePasswd, :updatePwd, :settings, :save_settings]

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :updatePwd ],
         :redirect_to => HOME_ACTION 
  
  GROUP_KEY = 'employee'
  
  def settings
  end
  
  def save_settings
    if @user.update_attributes(params[:user].slice(:report_type, :default_project_id, :default_attendance, :user_periods, :eval_periods))
      flash[:notice] =  'Die Benutzereinstellungen wurden aktualisiert'
      redirect_to HOME_ACTION
    else      
      flash[:notice] = 'Die Benutzereinstellungen konnten nicht aktualisiert werden'
      render :action => 'settings'
    end
  end
  
  #Update userpwd
  def updatePwd
    if @user.checkPasswd(params[:pwd])
      if params[:change_pwd] === params[:change_pwd_confirmation]
        @user.setPasswd(params[:change_pwd])
        flash[:notice] = 'Das Passwort wurde aktualisiert'
        redirect_to :controller => 'evaluator'
      else
        flash[:notice] = 'Die Passwort Best&auml;tigung stimmt nicht mit dem Passwort &uuml;berein'
        render :controller =>'employee', :action => 'changePasswd', :id => @user.id
      end
    else
      flash[:notice] = 'Das alte Passwort ist falsch'
      render :controller =>'employee', :action => 'changePasswd', :id => @user.id
    end  
  end
  
  ##### helper methods for ManageController ##### 
  
  def modelClass
    Employee
  end
  
  def listActions
    [['Projekte', 'projectmembership', 'listProjects', true],   
     ['&Uuml;berzeit', 'overtime_vacation', 'list', true],
     ['Anstellungen', 'employment', 'list', true]]
  end  
    
  def editFields    
    [[:initial_vacation_days, 'Anfängliche Ferien'],
     [:management, 'GL']]    
  end
  
  def listFields
    [[:lastname, 'Nachname'],
     [:firstname, 'Vorname'], 
     [:shortname, 'Kürzel'],
     [:current_percent, 'Prozent'],
     [:management, 'GL']]
  end
  
  def formatColumn(attribute, value)
    return (value ? value.to_s + ' %' : 'keine') if :current_percent == attribute
    super  attribute, value 
  end 

end
