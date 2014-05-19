# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class EmployeeController < ManageController

  # Checks if employee came from login or from direct url
  before_action :authorize, except: [:changePasswd, :updatePwd, :settings, :save_settings]
  before_action :authenticate, only: [:changePasswd, :updatePwd, :settings, :save_settings]


  GROUP_KEY = 'employee'

  def settings
  end

  def save_settings
    attrs = params.require(:user).permit(:report_type, :default_project_id, :default_attendance,
                                         :user_periods, :eval_periods)
    if @user.update_attributes(attrs)
      flash[:notice] =  'Die Benutzereinstellungen wurden aktualisiert'
      redirect_to HOME_ACTION
    else
      flash[:notice] = 'Die Benutzereinstellungen konnten nicht aktualisiert werden'
      render action: 'settings'
    end
  end

  # Update userpwd
  def updatePwd
    if @user.checkPasswd(params[:pwd])
      if params[:change_pwd] === params[:change_pwd_confirmation]
        @user.setPasswd(params[:change_pwd])
        flash[:notice] = 'Das Passwort wurde aktualisiert'
        redirect_to controller: 'evaluator'
      else
        flash[:notice] = 'Die Passwort Best&auml;tigung stimmt nicht mit dem Passwort &uuml;berein'
        render controller: 'employee', action: 'changePasswd', id: @user.id
      end
    else
      flash[:notice] = 'Das alte Passwort ist falsch'
      render controller: 'employee', action: 'changePasswd', id: @user.id
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

  def formatColumn(attribute, value, entry)
    if :current_percent == attribute
      case value
      when nil then 'keine'
      when value.to_i then value.to_i.to_s + ' %'
      else value.to_s + ' %'
      end
    else
      super  attribute, value, entry
    end
  end

end
