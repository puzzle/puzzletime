#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class AbsencetimesController < WorktimesController
  self.permitted_attrs = [:absence_id, :report_type, :work_date, :hours,
                          :from_start_time, :to_end_time, :description]

  before_render_form :set_accounts
  after_destroy :send_email_notification

  def create
    if params[:absencetime].present? && params[:absencetime][:create_multi].present?
      create_multi_absence
    else
      super
    end
  end

  def update
    if entry.employee_id != @user.id
      redirect_to index_path
    else
      super
    end
  end

  protected

  def create_multi_absence
    @multiabsence = Forms::MultiAbsence.new
    @multiabsence.employee = Employee.find_by(id: employee_id)
    @multiabsence.attributes = params[:absencetime]
    if @multiabsence.valid?
      absences = @multiabsence.save
      flash[:notice] = "#{absences.length} Absenzen wurden erfasst"
      redirect_to action: 'index', week_date: @multiabsence.work_date
    else
      set_employees
      @create_multi = true
      @multiabsence.worktime.errors.each do |error|
        attr = error.attribute
        msg  = error.message
        entry.errors.add(attr, msg)
      end
      render 'new'
    end
  end

  def set_worktime_defaults
    @worktime.absence_id ||= params[:account_id]
  end

  def set_accounts(_all = false)
    @accounts = Absence.list
  end

  def generic_evaluation
    'absences'
  end

  def check_has_accounting_post
    true
  end

  def send_email_notification
    if @worktime.employee != @user
      ::EmployeeMailer.worktime_deleted_mail(@worktime, @user).deliver_now
    end
  end
end
