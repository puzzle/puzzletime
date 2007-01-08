# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class EmployeeController < ApplicationController

  # Checks if employee came from login or from direct url
  before_filter :authorize, :except => [:changePasswd, :updatePwd]
  before_filter :authenticate, :only => [:changePasswd, :updatePwd]

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :deleteEmployee, :deleteEmployment, 
                                      :createEmployee, :createEmployment, 
                                      :updateEmployee, :updateEmployment ],
         :redirect_to => { :action => :listEmployee }
  
  # Lists all employees
  def listEmployee
    @employee_pages, @employees = paginate :employees, :per_page => 10 , :order => 'lastname'
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
      redirect_to :action => 'showEmployee', :id => @employee
    else
      render :action => 'newEmployee'
    end
  end
  
    # Shows the editpage of chosen employee
  def editEmployee
    @employee = Employee.find(params[:id])
  end

  # Stores the changed employee
  def updateEmployee
    @employee = Employee.find(params[:id])
    if @employee.update_attributes(params[:employee])
      flash[:notice] = 'Employee was successfully updated.'
      redirect_to :action => 'listEmployee'
    else
      flash[:notice] = 'Problem on updating employee'
      render :action => 'editEmployee'
    end
  end
  
  def confirmDeleteEmployee
    @employee = Employee.find(params[:id])
  end
  
  def deleteEmployee
    if Employee.destroy(params[:id])
      flash[:notice] = 'Employee was deleted'      
    else
      flash[:notice] = 'Problem on deleting employee'
    end
    redirect_to :action => 'listEmployee'
  end
  
  # Create employment data
  def createEmployment
    @employee = Employee.find(params[:id]) 
    
    begin
      @employment = Employment.new(params[:employment])
    rescue ActiveRecord::MultiparameterAssignmentErrors => ex
      ex.errors.each { |err| params[:employment].delete_if { |key, value| key =~ /^#{err.attribute}/ } }
      @employment = Employment.new(params[:employment])
      @employment.errors.add(:start_date, "is invalid")
      render :action => 'showEmployee', :id => @employee
      return
    end
    @employment.employee = @employee
    if @employment.save
      flash[:notice] = 'Employment was successfully created'
      redirect_to :action => 'showEmployee', :id => @employee
    else 
      render :action => 'showEmployee', :id => @employee
    end  
  end
  
  # Editpage employment data
  def editEmployment
    @employment = Employment.find(params[:id])
    @employee = Employee.find(params[:employee_id])
  end
  
    # Update employment data
  def updateEmployment
   @employee = Employee.find(params[:employee_id])
   @employment = Employment.find(params[:id])
   attributes = params[:employment]
   if ! params[:final]
      attributes.delete_if {|key, value| key =~ /^end_date/ }
      @employment.end_date = nil
   end   
   
   begin
     @employment.attributes = attributes
   rescue ActiveRecord::MultiparameterAssignmentErrors => ex
     ex.errors.each { |err| params[:employment].delete_if { |key, value| key =~ /^#{err.attribute}/ } }
     @employment.attributes = attributes
     @employment.errors.add_to_base("Date is invalid")
     render :action => 'editEmployment'
   end
   
   if @employment.save
      flash[:notice] = 'Employment was successfully updated.'
      redirect_to :action => 'showEmployee', :id => @employee
   else
     flash[:notice] = 'Employment was not updated.'
     render :action => 'editEmployment'
   end
 end 
 
  def confirmDeleteEmployment
    @employee = Employee.find(params[:employee_id])
    @employment = Employment.find(params[:employment_id])
  end
  
  # Deletes the chosen employment data
  def deleteEmployment
    @employee = Employee.find(params[:employee_id])
    if Employment.destroy(params[:employment_id])
      flash[:notice] = 'Employment was deleted'
      redirect_to :action => 'showEmployee', :id => @employee
    else
      flash[:notice] = 'Problem on deleting employment'
      render :action => 'showEmployee', :id => @employee
    end
  end
  
  #Update userpwd
  def updatePwd
    if Employee.checkpwd(@user.id, params[:pwd])
      if params[:change_pwd] === params[:change_pwd_confirmation]
        @user.updatepwd(params[:change_pwd])
        flash[:notice] = 'Password was successfully updated.'
        redirect_to :controller =>'worktime', :action => 'listTime', :id => @user.id
      else
        flash[:notice] = 'Password confirmation does not match'
        render :controller =>'employee', :action => 'changePasswd', :id => @user.id
      end
    else
     flash[:notice] = 'Old password does not match.'
     render :controller =>'employee', :action => 'changePasswd', :id => @user.id
    end  
  end

end
