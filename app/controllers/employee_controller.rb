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
  
  def index
    redirect_to :action => 'listEmployee'
  end
  
  # Lists all employees
  def listEmployee
    @employee_pages, @employees = paginate :employees, :per_page => NO_OF_OVERVIEW_ROWS, :order => 'lastname'
  end
  
  # Shows detail of chosen Employee 
  def showEmployee
    @employee = Employee.find(params[:id])
  end
  
  # Creates new employee
  def createEmployee
    @employee = Employee.new(params[:employee])
    if @employee.save
      flash[:notice] = 'Der Mitarbeiter wurde erfassen'
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
      flash[:notice] = 'Der Mitarbeiter wurde aktualisiert'
      redirect_to :action => 'listEmployee'
    else
      flash[:notice] = 'Der Mitarbeiter konnte nicht aktualisiert werden'
      render :action => 'editEmployee'
    end
  end
  
  def confirmDeleteEmployee
    @employee = Employee.find(params[:id])
  end
  
  def deleteEmployee
    if Employee.destroy(params[:id])
      flash[:notice] = 'Der Mitarbeiter wurde entfernt'      
    else
      flash[:notice] = 'Der Mitarbeiter konnte nicht entfernt werden'
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
      flash[:notice] = 'Die Anstellung wurde erfasst'
      redirect_to :action => 'showEmployee', :id => @employee
    else 
      flash[:notice] = 'Die Anstellung konnte nicht erfasst werden'
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
     @employment.errors.add_to_base("Datum ist ungültig")
     render :action => 'editEmployment'
   end
   
   if @employment.save
      flash[:notice] = 'Die Anstellung wurde aktualisiert'
      redirect_to :action => 'showEmployee', :id => @employee
   else
     flash[:notice] = 'Die Anstellung konnte nicht aktualisiert werden'
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
      flash[:notice] = 'Die Anstellung wurde entfernt'
      redirect_to :action => 'showEmployee', :id => @employee
    else
      flash[:notice] = 'Die Anstellung konnte nicht entfernt werden'
      render :action => 'showEmployee', :id => @employee
    end
  end
  
  #Update userpwd
  def updatePwd
    if Employee.checkpwd(@user.id, params[:pwd])
      if params[:change_pwd] === params[:change_pwd_confirmation]
        @user.updatepwd(params[:change_pwd])
        flash[:notice] = 'Das Passwort wurde aktualisiert'
        redirect_to :controller =>'worktime', :action => 'listTime', :id => @user.id
      else
        flash[:notice] = 'Die Passwort Best&auml;tigung stimmt nicht mit dem Passwort &uuml;berein'
        render :controller =>'employee', :action => 'changePasswd', :id => @user.id
      end
    else
     flash[:notice] = 'Das alte Passwort ist falsch'
     render :controller =>'employee', :action => 'changePasswd', :id => @user.id
    end  
  end

end
