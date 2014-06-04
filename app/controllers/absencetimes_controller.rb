# encoding: utf-8

class AbsencetimesController < WorktimesController

  def add_multi_absence
    set_accounts
    @multiabsence = MultiAbsence.new
  end

  def create_multi_absence
    @multiabsence = MultiAbsence.new
    @multiabsence.employee = @user
    @multiabsence.attributes = params[:multiabsence]
    if @multiabsence.valid?
      count = @multiabsence.save
      flash[:notice] = "#{count} Absenzen wurden erfasst"
      options = { controller: 'evaluator',
                  action: detail_action,
                  evaluation: user_evaluation,
                  clear: 1 }
      set_period
      if @period.nil? ||
          (! @period.include?(@multiabsence.start_date) ||
          ! @period.include?(@multiabsence.end_date))
        options[:start_date] = @multiabsence.start_date
        options[:end_date] = @multiabsence.end_date
      end
      redirect_to options
    else
      set_accounts
      render action: 'add_multi_absence'
    end
  end

  protected

  def set_new_worktime
    @worktime = Absencetime.new
  end

  def set_worktime_defaults
    @worktime.absence_id ||= params[:account_id]
  end

  def set_accounts(all = false)
    @accounts = Absence.list
  end

  def user_evaluation
    @user.absences(true)
    record_other? ? 'employeeabsences' : 'userAbsences'
  end

  def model_params
    attrs = [:account_id, :report_type, :work_date, :hours,
             :from_start_time, :to_end_time, :description]
    attrs << :employee_id if @user.management
    params.require(:worktime).permit(attrs)
  end
end
