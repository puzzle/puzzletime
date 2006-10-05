# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class AbsenceController < ApplicationController

  # Checks if employee came from login or from direct url
  before_filter :authorize
  
  #List all absences
  def listAbsence
     @absence_pages, @absences = paginate :absences, :per_page => 10
  end

  #Show Page for absence
  def newAbsence
    Absence.new(params[:absence])
  end
  
  # Creates new absence in DB  
  def createAbsence
    @absence = Absence.new(params[:absence])
    if @absence.save
      flash[:notice] = 'New absence was added'
      redirect_to :action => 'listAbsence'
    else
      render :action => 'createAbsence'
    end   
  end
  
  # Shows the editpage
  def editAbsence
    @absence = Absence.find(params[:id])
  end
  
  # Update the selected absence on DB
  def updateAbsence
    @absence = Absence.find(params[:id])
    if @absence.update_attributes(params[:absence])
      flash[:notice] = 'Absence was updated'
      redirect_to :action => 'listAbsence'
    else
      render :action => 'editAbsence', :id => @absence
    end
  end
  
  #Destroy the selected absence
  def destroyAbsence
    @absence = Absence.find(params[:id])
    if @absence.destroy
      flash[:notice] = 'Absence was deleted'
      redirect_to :action => 'listAbsence'
    else
      flash[:notice] ='Absence was not deleted'
      render :action =>'list'
    end
  end
end
