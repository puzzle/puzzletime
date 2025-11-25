# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class EmployeesController < ManageController
  self.permitted_attrs = [:firstname, :lastname, :shortname, :email, :ldapname, :department_id,
                          :member_coach_id, :workplace_id, :crm_key, :probation_period_end_date,
                          :graduation, :management, :phone_office, :phone_private,
                          :street, :postal_code, :city, :birthday, :emergency_contact_name,
                          :emergency_contact_phone, :marital_status,
                          :social_insurance, :additional_information,
                          :identity_card_type, :identity_card_valid_until,
                          { nationalities: [] }]

  self.permitted_attrs += [:initial_vacation_days] if Settings.employees.initial_vacation_days_editable

  self.search_columns = %i[firstname lastname shortname]

  self.sort_mappings = { department_id: 'departments.name' }

  def show
    return if Crm.instance.blank?

    person = Crm.instance.find_people_by_email(entry.email).first
    if person
      redirect_to Crm.instance.contact_url(person.id), allow_other_host: true
    else
      flash[:alert] = "Person mit Email '#{entry.email}' nicht gefunden in CRM."
    end
  end

  def settings
    @employee = @user
  end

  def update_settings
    @employee = @user
    attrs = params.require(:employee).permit(:worktimes_commit_reminder, eval_periods: [])
    attrs[:eval_periods] = [] if attrs[:eval_periods].blank?
    if @employee.update(attrs)
      flash[:notice] = 'Die Benutzereinstellungen wurden aktualisiert'
      redirect_to root_path
    else
      render action: 'settings'
    end
  end

  private

  def list_entries
    super.includes(:department).references(:department)
  end
end
