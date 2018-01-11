class EmployeeMailer < ActionMailer::Base
  add_template_helper FormatHelper

  def worktime_deleted_mail(worktime, deleted_by)
    @worktime = worktime
    @deleted_by = deleted_by

    mail(from: Settings.mailer.employee.worktime_deleted.from,
         to: worktime.employee.email,
         subject: 'PuzzleTime-Eintrag wurde gelöscht')
  end
end
