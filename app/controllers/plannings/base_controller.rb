# encoding: utf-8

module Plannings
  class BaseController < ListController

    include WithPeriod

    self.allow_unlimited_period = false

    before_action :authorize_subject_planning

    define_render_callbacks :show, :new, :update

    before_action :set_period

    def show
      @board = build_board
    end

    # new row for plannings
    def new
      board = build_board
      board.for_rows([[params[:employee_id], params[:work_item_id]]])
      @items = board.rows.values.first
      @legend = board.row_legend(params[:employee_id], params[:work_item_id])
      @row_total = board.total_row_hours(params[:employee_id], params[:work_item_id])
    end

    def update
      creator = Plannings::Creator.new(params_with_restricted_items)
      respond_to do |format|
        if creator.create_or_update
          format.js { @board = build_board_for(creator.plannings) }
        else
          format.js { render :errors, locals: { errors: creator.errors } }
        end
      end
    end

    def destroy
      destroy_plannings
      respond_to do |format|
        format.js do
          @board = build_board_for(@plannings)
          render :update
        end
      end
    end

    private

    def destroy_plannings
      Planning.transaction do
        @plannings = plannings_to_destroy
        @plannings.each(&:destroy)
      end
    end

    def plannings_to_destroy
      Planning.where(id: Array(params[:planning_ids]))
    end

    def params_with_restricted_items
      { items: params[:items].is_a?(Hash) ? params[:items].values : params[:items] || [],
        planning: params[:planning] || {} }
    end

    def build_board_for(plannings)
      build_board.tap do |board|
        board.for_rows(plannings.collect { |p| [p.employee_id, p.work_item_id] }.uniq)
      end
    end

    def set_period
      period = build_period
      if period.nil?
        period = session[:planning_period] || default_period
      elsif period.unlimited?
        period = default_period
      end
      period = period.extend_to_weeks
      @period = session[:planning_period] = period
    end

    def default_period
      Period.next_n_months(3)
    end

    def authorize_subject_planning
      case action_name
      when 'index' then authorize!(:read, Planning)
      when 'show' then  authorize!(:show_plannings, subject)
      else authorize!(:manage_plannings, subject)
      end
    end

  end
end
