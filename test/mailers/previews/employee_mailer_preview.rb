# frozen_string_literal: true

class EmployeeMailerPreview < ActionMailer::Preview
  def worktime_deleted_mail
    worktime_user = Employee.new(email: 'user@example.com', firstname: 'Peter', lastname: 'Puzzler')
    worktime = Ordertime.new(
      employee: worktime_user,
      account: WorkItem.new(name: 'Lieblingsprojekt', path_shortnames: 'TOP-FAV'),
      work_date: Time.zone.today,
      hours: 4.33,
      report_type: ReportType::HoursDayType::INSTANCE
    )
    management_user = Employee.new(firstname: 'Mad', lastname: 'Manager')
    EmployeeMailer.worktime_deleted_mail(worktime, management_user)
  end

  def worktime_commit_reminder_mail
    employee = Employee.new(email: 'user@example.com', firstname: 'Peter', lastname: 'Puzzler')
    EmployeeMailer.worktime_commit_reminder_mail(employee)
  end
end
