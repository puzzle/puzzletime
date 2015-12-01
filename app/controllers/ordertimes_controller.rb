# encoding: utf-8

class OrdertimesController < WorktimesController

  self.permitted_attrs = [:account_id, :report_type, :work_date, :hours,
                          :from_start_time, :to_end_time, :description, :billable, :ticket]

  before_save :check_worktimes_committed

  def update
    if entry.employee_id != @user.id
      session[:split] = WorktimeEdit.new(entry)
      create_part
    else
      super
    end
  end

  def split
    set_employees
    @split = session[:split]
    if @split.nil?
      redirect_to controller: 'ordertimes', action: 'new'
    else
      @worktime = @split.worktime_template
      render action: 'split'
    end
  end

  def create_part
    set_employees
    @split = session[:split]
    return create if @split.nil?
    @worktime ||= @split.build_worktime
    @worktime.employee ||= @split.original.employee
    params[:other] = '1'
    assign_attributes
    if @worktime.valid? && @split.add_worktime(@worktime)
      if @split.complete? || (params[:commit] == FINISH && @split.incomplete_finish)
        @split.save
        session[:split] = nil
        flash[:notice] = 'Alle Arbeitszeiten wurden erfasst'
        if @worktime.employee != @user
          params[:other] = '1'
          params[:evaluation] = nil
        end
        redirect_to index_path
      else
        session[:split] = @split
        redirect_to action: 'split', back_url: params[:back_url]
      end
    else
      render action: 'split'
    end
  end

  def delete_part
    session[:split].remove_worktime(params[:part_id].to_i)
    redirect_to action: 'split', back_url: params[:back_url]
  end

  protected

  def set_worktime_defaults
    @worktime.work_item_id ||= params[:account_id]
  end

  def check_worktimes_committed
    if entry.employee_id == @user.id && entry.worktimes_committed?
      date = I18n.l(@user.committed_worktimes_at, format: :month)
      entry.errors.add(:work_date, "Die Zeiten bis und mit #{date} wurden freigegeben " \
                                   'und können nicht mehr bearbeitet werden.')
      false
    end
  end

end
