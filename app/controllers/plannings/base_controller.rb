module Plannings
  class BaseController < ApplicationController

    include WithPeriod

    before_action :authorize_class
    before_action :set_period

    def show
    end

    # new row for plannings
    def new
    end

    def update
      @creator = Plannings::Creator.new(params)
      respond_to do |format|
        if @creator.create_or_update
          format.js   { }
          format.json { render :show, status: :ok }
        else
          format.js   { render :errors }
          format.json { render json: @creator.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      destroy_plannings
      respond_to do |format|
        format.js   { render :update }
        format.json { head :no_content }
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
