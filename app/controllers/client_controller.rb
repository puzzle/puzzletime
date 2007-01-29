# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class ClientController < ApplicationController

  # Checks if employee came from login or from direct url
  before_filter :authorize
  
  verify :method => :post, :only => [ :deleteClient ],
         :redirect_to => { :action => :listClient }

  def index
    redirect_to :action => 'listClient'
  end
  
  # Lists all clients
  def listClient
    @client_pages, @clients = paginate :clients, :order => 'name', :per_page => NO_OF_OVERVIEW_ROWS
  end
  
  # Shows detail of chosen client
  def showClient
    @client = Client.find(params[:id])
  end
  
  # Creates new instance of client
  def newClient
    @client = Client.new
  end
  
  # Saves new client on db
  def createClient
    @client = Client.new(params[:client])
    if @client.save
      flash[:notice] = 'Der Kunde wurde erfasst'
      redirect_to :action => 'listClient'
    else
      render :action => 'newClient'
    end
  end
  
  # Shows the editpage of client
  def editClient
    @client = Client.find(params[:id])
  end
  
  # Stores the updated attributes of client
  def updateClient
    @client = Client.find(params[:id])
    if @client.update_attributes(params[:client])
      flash[:notice] = 'Der Kunde wurde aktualisiert'
      redirect_to :action => 'listClient', :id => @client
    else
      flash[:notice] = 'Der Kunde konnte nicht aktualisiert werden'
      render :action => 'editClient'
    end
  end
  
  def confirmDeleteClient
    @client = Client.find(params[:id])
  end
  
  def deleteClient
    begin
       Client.destroy(params[:id])
       flash[:notice] = 'Der Kunde wurde entfernt'
    rescue Exception => err
       flash[:notice] = err.message
    end   
    redirect_to :action => 'listClient'
  end
end
