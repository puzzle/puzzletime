# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class EmployeesController < ManageController

  self.permitted_attrs = [:firstname, :lastname, :shortname, :email, :ldapname,
                          :initial_vacation_days, :department_id, :management]

  self.search_columns = [:firstname, :lastname, :shortname]

  self.sort_mappings = { department_id: 'departments.name' }

  def show
    # TODO: test
    if person = Crm.instance.find_people_by_email(entry.email).first
      redirect_to Crm.instance.contact_url(person.id)
    else
      flash[:alert] = "Person mit Email '#{entry.email}' nicht gefunden in CRM."
      render :crm_person_not_found
    end
  end

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

  private

  def list_entries
    super.includes(:department).references(:department)
  end

end
