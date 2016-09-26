# encoding: utf-8

module Plannings
  class BaseController < ListController

    include WithPeriod

    define_render_callbacks :show, :new, :update

    before_action :authorize_class
    before_action :set_period

    helper_method :entry

    def show
      @board = build_board
    end

    # new row for plannings
    def new
      board = build_board
      board.for_rows([params[:employee_id], params[:work_item_id]])
      @items = board.rows.values.first
    end

    def update
      creator = Plannings::Creator.new(params)
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
        @plannings = Planning.where(id: Array(params[:planning_ids]))
        @plannings.each(&:destroy)
      end
    end

    def build_board_for(plannings)
      build_board.tap do |board|
        board.for_rows(plannings.collect { |p| [p.employee_id, p.work_item_id] }.uniq)
      end
    end

    def set_period
      convert_predefined_period
      period = super
      @period = period.limited? ? period.extend_to_weeks : default_period
    end

    def convert_predefined_period
      return if params[:period].blank?

      @period = Period.parse(params.delete(:period))
      if @period
        params[:start_date] = I18n.l(@period.start_date)
        params[:end_date] = I18n.l(@period.end_date)
      end
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
