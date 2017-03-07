class VacationsController < ApplicationController

  before_action :authorize_action
  before_action :set_period

  def show
    @graph = VacationGraph.new(@period)
  end

  private

  def authorize_action
    authorize!(:show_vacations, Absencetime)
  end

end
