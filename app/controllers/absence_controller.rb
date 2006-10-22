# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class AbsenceController < ApplicationController

  # Checks if employee came from login or from direct url.
  before_filter :authorize
  
  # List all absences.
  def listAbsence
     @absence_pages, @absences = paginate :absences, :per_page => 10
  end

  # Show Page for absence.
  def newAbsence
    Absence.new(params[:absence])
  end
  
  # Shows editAbsenceTime page.
  def editAbsenceTime
    @employee = Employee.find(params[:employee_id])
    @absence = Absence.find(:all)
    @worktime = Worktime.find(params[:worktime_id])
  end
  
  # Saves the updated absence attributes on DB.
  def updateAbsenceTime
    @worktime = Worktime.find(params[:worktime_id])
    if @worktime.update_attributes(params[:worktime])
      flash[:notice] = 'Absence Time was successfully updated.'   
      redirect_to :controller => 'evaluator' ,:action => 'showAbsences'
    else
      render :action => 'editAbsenceTime'
    end
  end

  # Deletes the selected absence time from DB.
  def deleteAbsenceTime
    @worktime = Worktime.find(params[:worktime_id])
    if @worktime.destroy
      flash[:notice] = 'Absence Time was deleted'
      redirect_to :controller => 'evaluator' ,:action => 'showAbsences'
    else
      flash[:notice] ='Absence Time was not deleted'
      render :controller => 'evaluator' ,:action =>'showAbsences'
    end
  end
end
