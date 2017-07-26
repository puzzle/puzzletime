# encoding: utf-8

class WeeklyGraphController < ApplicationController

  before_action :authorize
  before_action :set_period

  def show
    @graph = WorktimeGraph.new(@period || Period.past_month, worktime_graph_user)
  end

  private

  def worktime_graph_user
    @worktime_graph_user ||= Employee.find(params[:employee_id])
  end

  def authorize
    authorize!(:show_worktime_graph, worktime_graph_user)
  end

end
