# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class AbsenceController < ApplicationController

  # Checks if employee came from login or from direct url.
  before_filter :authorize
  
  # List all absences.
  def listAbsence
     @absence_pages, @absences = paginate :absences, :order => 'name', :per_page => 10
  end

  # Show Page for absence.
  def newAbsence
    Absence.new(params[:absence])
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
  
end
