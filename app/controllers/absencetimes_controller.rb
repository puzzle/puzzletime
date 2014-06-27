class AbsencetimesController < WorktimesController

  self.permitted_attrs = [:absence_id, :report_type, :work_date, :hours,
                          :from_start_time, :to_end_time, :description]

  before_render_form :set_accounts

  def create
    if params[:absencetime].present? && params[:absencetime][:create_multi].present?
      create_multi_absence
    else
      super
    end
  end

  def update
    if entry.employee_id != @user.id
      redirect_to index_url
    else
      super
    end
  end

  protected

  def create_multi_absence
    @multiabsence = MultiAbsence.new
    @multiabsence.employee = @user
    @multiabsence.attributes = params[:absencetime]
    if @multiabsence.valid?
      count = @multiabsence.save
      flash[:notice] = "#{count} Absenzen wurden erfasst"
      redirect_to action: 'index', week_date: @multiabsence.work_date
    else
      @create_multi = true
      flash[:notice] = @multiabsence.worktime.errors.full_messages.to_sentence
      render 'new'
    end
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

end
