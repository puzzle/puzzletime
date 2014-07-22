# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class EmployeesController < ManageController

  self.permitted_attrs = [:initial_vacation_days, :management]

  before_action :authorize, except: [:changePasswd, :update_pwd,
                                     :settings, :update_settings]


  def settings
  end

  def update_settings
    attrs = params.require(:user).permit(eval_periods: [])
    if @user.update_attributes(attrs)
      flash[:notice] =  'Die Benutzereinstellungen wurden aktualisiert'
      redirect_to root_path
    else
      flash[:notice] = 'Die Benutzereinstellungen konnten nicht aktualisiert werden'
      render action: 'settings'
    end
  end

  def passwd
  end

  # Update userpwd
  def update_passwd
    if @user.check_passwd(params[:pwd])
      if params[:change_pwd] === params[:change_pwd_confirmation]
        @user.set_passwd(params[:change_pwd])
        flash[:notice] = 'Das Passwort wurde aktualisiert'
        redirect_to controller: 'evaluator'
      else
        flash[:notice] = 'Die Passwort Bestätigung stimmt nicht mit dem Passwort überein'
        render 'passwd'
      end
    else
      flash[:notice] = 'Das alte Passwort ist falsch'
      render 'passwd'
    end
  end

end
