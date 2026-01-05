# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class OrdertimesController < WorktimesController
  self.permitted_attrs = %i[account_id report_type work_date hours meal_compensation
                            from_start_time to_end_time description internal_description billable ticket]

  after_destroy :send_email_notification

  def create
    repetitions = params[:ordertime][:repetitions].to_i.nonzero? || 1
    if repetitions > 1
      @multi_form = Forms::MultiOrdertime.new(params.require(:ordertime).permit(permitted_attrs + [:repetitions]))
      @multi_form.employee = Employee.find_by(id: employee_id)

      @multi_form.prepare_each.with_index do |ot_params, idx|
        @_params = ot_params
        model_ivar_set(Ordertime.new)

        is_last = idx == repetitions - 1
        super do |format|
          format.html { } unless is_last
        end
      end
    else
      super
    end
  end

  def update
    if entry.employee_id == @user.id && !entry.worktimes_committed?
      super
    else
      build_splitable
      create_part
    end
  end

  def split
    set_employees
    if splitable.nil?
      redirect_to controller: 'ordertimes', action: 'new'
    else
      @worktime = splitable.worktime_template
      render action: 'split'
    end
  end

  def create_part
    set_employees
    return create if splitable.nil?

    build_worktime
    params[:other] = '1'
    assign_attributes
    if @worktime.valid? && splitable.add_worktime(@worktime)
      if split_complete?
        save_split_and_return
      else
        session[:split] = splitable
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

  private

  def split_complete?
    splitable.complete? || (params[:commit] == FINISH && splitable.incomplete_finish)
  end

  def save_split_and_return
    splitable.save
    session[:split] = nil
    flash[:notice] = 'Alle Arbeitszeiten wurden erfasst'
    if worktime_employee?
      params[:other] = '1'
      params[:evaluation] = nil
    end
    redirect_to index_path
  end

  def worktime_employee?
    @worktime.employee != @user
  end

  def splitable
    @split ||= session[:split]
  end

  def build_splitable
    @split = session[:split] = Forms::WorktimeEdit.new(entry)
  end

  def build_worktime
    @worktime ||= splitable.build_worktime
    @worktime.employee ||= splitable.original.employee
  end

  def send_email_notification
    return unless worktime_employee?

    ::EmployeeMailer.worktime_deleted_mail(@worktime, @user).deliver_now
    flash[:warning] =
      "#{@worktime.employee} wurde per E-Mail darüber informiert, dass du diesen Eintrag gelöscht hast."
  end

  def execute_with_params(temp_params)
    original_params = params
    @_params = temp_params
    yield
  ensure
    @_params = original_params
  end
end
