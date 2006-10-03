# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class EmployeeController < ApplicationController

  # Checks if employee came from login or from direct url
  before_filter :authorize
  
  # Startpoint
  def index
    list
    render :action => 'listEmployee'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }
  
  # Lists all employees
  def listEmployee
    @employee_pages, @employees = paginate :employees, :per_page => 10
  end
  
  # Shows detail of chosen Employee 
  def showEmployee
    @employee = Employee.find(params[:id])
  end
  
  # Creates new employee
  def createEmployee
    @employee = Employee.new(params[:employee])
    if @employee.save
      flash[:notice] = 'Employee was successfully created.'
      redirect_to :action => 'list'
    else
      flash[:notice] = 'Employee was not created.'
      render :action => 'new'
    end
  end
  
  # Create employment data
  def createEmployment
    employee = Employee.find(params[:id])
    @employment = @employee.employments.create(params[:employment])
    if @employment.save
      flash[:notice] = 'Employment was successfully created'
      redirect_to :action => 'listEmployee'
    else 
      flash[:notice] = 'Employment was not created'
      redirect_to :action => 'showEmployee', :id => employee
    end  
  end
  
  # Editpage employment data
  def editEmployment
    @employment = Employment.find(params[:id])
    @employee = Employee.find(params[:id_employee])
  end
  
  #Changes userpwd
  def updatePwd
    if Employee.checkpwd(@user.id, params[:pwd])
      if params[:change_pwd] === params[:change_pwd_confirmation]
        @user.updatepwd(params[:change_pwd])
        flash[:notice] = 'Password was successfully updated.'
        redirect_to :controller =>'worktime', :action => 'list', :id => @user.id
      else
        flash[:notice] = 'Passwordconfirmation does not match'
        redirect_to :controller =>'employee', :action => 'changepasswd', :id => @user.id
      end
    else
     flash[:notice] = 'Old password does not match.'
     redirect_to :controller =>'employee', :action => 'changepasswd', :id => @user.id
    end  
  end
  
  # Update employment data
  def updateEmployment
    @employee = Employee.find(params[:id_employee]) 
    if Employment.find(params[:id]).update_attributes(params[:employment])
      flash[:notice] = 'Employment was successfully updated.'
      redirect_to :action => 'showEmployee', :id =>@employee
    else
      flash[:notice] = 'Please enter percent'
      redirect_to :action => 'editEmployment', :id => @employee
    end
  end
  
  # Deletes the chosen employment data
  def destroyEmployment
       @employee = Employee.find(params[:id_employee])
    if Employment.find(params[:id_employment]).destroy
      flash[:notice] = 'Employment was deleted'
      redirect_to :action => 'showEmployee', :id => @employee
    else
      flash[:notice] = 'Employment was not deleted'
      redirect_to :action => 'showEmployee', :id => @employee
    end
  end
  
  # Shows the editpage of chosen employee
  def editEmployee
    @employee = Employee.find(params[:id])
  end

  # Stores the changed employee
  def updateEmployee
    if Employee.find(params[:id]).update_attributes(params[:employee])
      flash[:notice] = 'Employee was successfully updated.'
      redirect_to :action => 'listEmployee'
    else
      flash[:notice] = 'Employee was not updated.'
      render :action => 'editEmployee'
    end
  end
  
  # Deletes the chosen employee
  def destroyEmployee
    @employee = Employee.find(params[:id])
    if @employee.destroy
        flash[:notice] = 'Employee was deleted'
      redirect_to :action => 'listEmployee'
    else
      flash[:notice] = 'Employee was not deleted'
      redirect_to :action => 'listEmployee'
    end
  end
end
