# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class EmployeesController < ManageController

  self.permitted_attrs = [:firstname, :lastname, :shortname, :email, :ldapname,
                          :department_id, :management]
  if Settings.employees.initial_vacation_days_editable
    self.permitted_attrs += [:initial_vacation_days]
  end

  self.search_columns = [:firstname, :lastname, :shortname]

  self.sort_mappings = { department_id: 'departments.name' }

  def show
    if Crm.instance.present?
      if person = Crm.instance.find_people_by_email(entry.email).first
        redirect_to Crm.instance.contact_url(person.id)
      else
        flash[:alert] = "Person mit Email '#{entry.email}' nicht gefunden in CRM."
      end
    end
  end

  def settings
  end

  def update_settings
    attrs = (params[:user] && params.require(:user).permit(eval_periods: [])) || {}
    attrs[:eval_periods] = [] if attrs[:eval_periods].blank?
    if @user.update_attributes(attrs)
      flash[:notice] = 'Die Benutzereinstellungen wurden aktualisiert'
      redirect_to root_path
    else
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
        flash.now[:notice] = 'Die Passwort Bestätigung stimmt nicht mit dem Passwort überein'
        render 'passwd'
      end
    else
      flash.now[:notice] = 'Das alte Passwort ist falsch'
      render 'passwd'
    end
  end

  private

  def list_entries
    super.includes(:department).references(:department)
  end
end
