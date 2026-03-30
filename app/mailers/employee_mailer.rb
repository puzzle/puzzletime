# frozen_string_literal: true

class EmployeeMailer < ApplicationMailer
  def worktime_deleted_mail(worktime, deleted_by)
    @worktime = worktime
    @deleted_by = deleted_by

    mail(to: worktime.employee.email,
         subject: 'PuzzleTime-Eintrag wurde gelöscht')
  end

  def worktime_commit_reminder_mail(employee)
    @employee = employee

    mail(
      to: "#{employee.firstname} #{employee.lastname} <#{employee.email}>",
      subject: 'PuzzleTime Zeiten freigeben'
    )
  end

  def not_billed_times_reminder_mail(employee_data)
    @employee_data = employee_data

    mail(
      to: "#{employee_data.firstname} #{employee_data.lastname} <#{employee_data.email}>",
      subject: "PTime: #{employee_data.client} - nicht verrechnete Leistungen im letzten Monat gefunden"
    )
  end
end
