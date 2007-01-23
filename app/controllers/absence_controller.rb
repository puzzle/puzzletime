# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class AbsenceController < ApplicationController

  # Checks if employee came from login or from direct url.
  before_filter :authorize
  
    # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :createAbsence, :updateAbsence, :deleteAbsence ],
         :redirect_to => { :action => :listAbsence }
        
  def index
    redirect_to :action => 'listAbsence'
  end
   
  def listAbsence
     @absence_pages, @absences = paginate :absences, :order => 'name', :per_page => NO_OF_OVERVIEW_ROWS
  end

  def newAbsence
    Absence.new(params[:absence])
  end
  
  def editAbsence
    @absence = Absence.find(params[:id])
  end

  def createAbsence
    @absence = Absence.new(params[:absence])
    if @absence.save
      flash[:notice] = 'Die Absenz wurde erstellt'
      redirect_to :action => 'listAbsence'
    else
      render :action => 'newAbsence'
    end
  end
  
  def updateAbsence
    @absence = Absence.find(params[:id])
    if @absence.update_attributes(params[:absence])
      flash[:notice] = 'Die Absenz wurde aktualisiert'
      redirect_to :action => 'listAbsence'
    else
      render :action => 'newAbsence'
    end
  end
  
  def confirmDeleteAbsence
    @absence = Absence.find(params[:id])
  end
  
  def deleteAbsence
    flash[:notice] = 'Die Absenz wurde entfernt'
    begin
      Absence.destroy(params[:id])
    rescue RuntimeError => err
      flash[:notice] = err.message
    end     
    
    redirect_to :action => 'listAbsence'
  end
  
end
