module Plannings
  class BaseController < ListController

    include WithPeriod

    before_action :authorize_class
    before_action :set_period

    def show
    end

    # new row for plannings
    def new
      @employee = Employee.find(params[:employee_id])
      @work_item = WorkItem.find(params[:work_item_id])
      list = load_plannings.where(employee_id: @employee.id,
                                  work_item_id: @work_item.id)
      @plannings = grouped_plannings(list)
    end

    def update
      creator = Plannings::Creator.new(params)
      respond_to do |format|
        if creator.create_or_update
          format.js { @plannings = changed_plannings(creator.plannings) }
        else
          format.js { render :errors }
        end
      end
    end

    def destroy
      destroy_plannings
      respond_to do |format|
        format.js do
          @plannings = changed_plannings(@plannings)
          render :update
        end
      end
    end

    private

    def grouped_plannings(plannings = load_plannings)
      plannings
    end

    def load_plannings
      Planning.in_period(@period).list
    end

    def destroy_plannings
      Planning.transaction do
        @plannings = Planning.where(id: Array(params[:planning_ids]))
        @plannings.each(&:destroy)
      end
    end

    def changed_plannings(plannings)
      condition = ['']
      plannings.collect { |p| [p.work_item_id, p.employee_id] }.uniq.each do |work_item_id, employee_id|
        condition[0] += ' OR ' unless condition.first.blank?
        condition[0] += '(plannings.work_item_id = ? AND plannings.employee_id = ?)'
        condition << work_item_id << employee_id
      end
      grouped_plannings(load_plannings.where(condition))
    end

    def set_period
      period = super
      @period = period.limited? ? period.extend_to_weeks : default_period
    end

    def default_period
      today = Time.zone.today
      Period.retrieve(today.at_beginning_of_week, (today + 3.month).at_end_of_week)
    end

    def authorize_class
      authorize!(action_name.to_sym, Planning)
    end

  end
end
