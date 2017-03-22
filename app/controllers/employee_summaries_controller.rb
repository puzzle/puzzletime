class EmployeeSummariesController < ApplicationController

  before_action :authorize_action

  def index
    @employees = Employee.employed_ones(Period.current_year)
                         .includes(:department)
                         .page(params[:page])
                         .list
  end

  def show
    @employee = Employee.find(params[:id])
  end

  def authorize_action
    authorize!(:read, Employee)
  end

end
