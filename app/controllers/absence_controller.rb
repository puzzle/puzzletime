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
  
  # Shows editAbsence page.
  def editAbsence
    @absence = Absence.find(params[:id])
  end

  # Saves the new absence on the DB.
  def createAbsence
    @absence = Absence.new(params[:absence])
    if @absence.save
      flash[:notice] = 'Absence was successfully created'
      redirect_to :action => 'listAbsence'
    else
      render :action => 'newAbsence'
    end
  end
  
  # Update the selected absence on DB.
  def updateAbsence
    @absence = Absence.find(params[:id])
    if @absence.update_attributes(params[:absence])
      flash[:notice] = 'Absence was successfully created'
      redirect_to :action => 'listAbsence'
    else
      render :action => 'newAbsence'
    end
  end
  
  # Deletes selected absence from the DB.
  def destroyAbsence
    if Absence.delete(params[:id])
      flash[:notice] = 'Absence was successfully removed'
      redirect_to :action => 'listAbsence'
    else
      render :action => 'listAbsence'
    end
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
    if Worktime.destroy(params[:worktime_id])
      flash[:notice] = 'Absence Time was deleted'
      redirect_to :controller => 'evaluator' ,:action => 'showAbsences'
    else
      flash[:notice] ='Absence Time was not deleted'
      render :controller => 'evaluator' ,:action =>'showAbsences'
    end
  end
end
