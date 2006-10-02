# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class EmployeeController < ApplicationController

  # Checks if employee came from login or from direct url
  before_filter :authorize
  
  # Startpoint
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }
  
  # Lists all employees
  def list
    @employee_pages, @employees = paginate :employees, :per_page => 10
  end
  
  # Shows detail of chosen Employee 
  def show
    @employee = Employee.find(params[:id])
  end
  
  # Creates new employee
  def create
    @employee = Employee.new(params[:employee])
    if @employee.save
      flash[:notice] = 'Employee was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end
  
  # Records employment data
  def recordEmployment
    @employee = Employee.find(params[:id])
    @employment = @employee.employments.create(params[:employment])
    if @employment.save
      flash[:notice] = 'Employment was successfully created'
      redirect_to :action => 'show', :id => @employee
    end  
  end
  
  # Editpage employment data
  def editemployment
    @employment = Employment.find(params[:id])
  end
  
  def updatepwd
    
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
     flash[:notice] = 'Old password did not match.'
     redirect_to :controller =>'employee', :action => 'changepasswd', :id => @user.id
    end  
  end
  
  # Update employment data
  def updateemployment
    @employment = Employment.find(params[:id])
    if @employment.update_attributes(params[:employment])
      flash[:notice] = 'Employment was successfully updated.'
      redirect_to :action => 'list'
    else
      flash[:notice] = 'Please enter percent'
      redirect_to :action => 'editEmployment', :id => @employment
    end
  end
  
  # Deletes the chosen employment data
  def destroyemployment
    Employment.find(params[:id_employment]).destroy
    redirect_to :action => 'show', :id => @user
  end
  
  # Shows the editpage of chosen employee
  def edit
    @employee = Employee.find(params[:id])
  end

  # Stores the changed employee
  def update
    @employee = Employee.find(params[:id])
    if @employee.update_attributes(params[:employee])
      flash[:notice] = 'Employee was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end
  
  # Deletes the chosen employee
  def destroy
    Employee.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
