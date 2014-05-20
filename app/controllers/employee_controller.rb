# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class EmployeeController < ManageController

  # Checks if employee came from login or from direct url
  before_action :authorize, except: [:changePasswd, :update_pwd, :settings, :save_settings]
  before_action :authenticate, only: [:changePasswd, :update_pwd, :settings, :save_settings]


  GROUP_KEY = 'employee'

  def settings
  end

  def save_settings
    attrs = params.require(:user).permit(:report_type, :default_project_id, :default_attendance,
                                         :user_periods, :eval_periods)
    if @user.update_attributes(attrs)
      flash[:notice] =  'Die Benutzereinstellungen wurden aktualisiert'
      redirect_to root_path
    else
      flash[:notice] = 'Die Benutzereinstellungen konnten nicht aktualisiert werden'
      render action: 'settings'
    end
  end

  # Update userpwd
  def update_pwd
    if @user.check_passwd(params[:pwd])
      if params[:change_pwd] === params[:change_pwd_confirmation]
        @user.set_passwd(params[:change_pwd])
        flash[:notice] = 'Das Passwort wurde aktualisiert'
        redirect_to controller: 'evaluator'
      else
        flash[:notice] = 'Die Passwort Bestätigung stimmt nicht mit dem Passwort überein'
        render controller: 'employee', action: 'changePasswd', id: @user.id
      end
    else
      flash[:notice] = 'Das alte Passwort ist falsch'
      render controller: 'employee', action: 'changePasswd', id: @user.id
    end
  end

  ##### helper methods for ManageController #####

  def model_class
    Employee
  end

  def list_actions
    [['Projekte', 'projectmembership', 'list_projects', true],
     ['Überzeit', 'overtime_vacation', 'list', true],
     ['Anstellungen', 'employment', 'list', true]]
  end

  def edit_fields
    [[:initial_vacation_days, 'Anfängliche Ferien'],
     [:management, 'GL']]
  end

  def list_fields
    [[:lastname, 'Nachname'],
     [:firstname, 'Vorname'],
     [:shortname, 'Kürzel'],
     [:current_percent, 'Prozent'],
     [:management, 'GL']]
  end

  def format_column(attribute, value, entry)
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
