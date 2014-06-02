# encoding: utf-8

class EmployeeListsController < ApplicationController

  before_action :set_period


  # GET /employee_lists/1
  # GET /employee_lists/1.xml
  def show
    @employee_list = EmployeeList.find(params[:id])
    @employees = @employee_list.employees.sort_by(&:lastname)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @employee_list }
    end
  end

  # GET /employee_lists/new
  # GET /employee_lists/new.xml
  def new
    @employee_list = EmployeeList.new
    @curr_employees = Employee.employed_ones(@period || Period.past_month)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @employee_list }
    end
  end

  # GET /employee_lists/1/edit
  def edit
    @employee_list = EmployeeList.find(params[:id])
    @curr_employees = Employee.employed_ones(@period || Period.past_month)
  end

  # POST /employee_lists
  # POST /employee_lists.xml
  def create
    @employee_list = EmployeeList.new(params[:employee_list])
    @employee_list.employee_id = @user.id # add current user id to the created object

    # logger.debug "employees = #{@employee_list.employees.inspect}"
    respond_to do |format|
      if @employee_list.save
        flash[:notice] = 'Mitarbeiterliste wurde erfolgreich erstellt.'
        # format.html { redirect_to(@employee_list) }
        format.html { redirect_to controller: 'plannings', action: 'employee_lists' }
        format.xml  { render xml: @employee_list, status: :created, location: @employee_list }
      else
        format.html do
          @curr_employees = Employee.employed_ones(@period || Period.past_month)
          render action: 'new'
        end
        format.xml  { render xml: @employee_list.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /employee_lists/1
  # PUT /employee_lists/1.xml
  def update

    params[:employee_list][:employee_ids] ||= []

    @employee_list = EmployeeList.find(params[:id])

    respond_to do |format|
      if @employee_list.update_attributes(params[:employee_list])
        flash[:notice] = 'Mitarbeiterliste wurde erfolgreich angepasst.'
        # format.html { redirect_to(@employee_list) }
        format.html { redirect_to controller: 'plannings', action: 'employee_lists' }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @employee_list.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /employee_lists/1
  # DELETE /employee_lists/1.xml
  def destroy
    @employee_list = EmployeeList.find(params[:id])
    @employee_list.destroy

    respond_to do |format|
      # format.html { redirect_to(employee_lists_url) }
      format.html { redirect_to controller: 'plannings', action: 'employee_lists' }
      format.xml  { head :ok }
    end
  end

end
