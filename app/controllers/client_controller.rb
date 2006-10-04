# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class ClientController < ApplicationController

  # Checks if employee came from login or from direct url
  before_filter :authorize

  # Lists all clients
  def listClient
    @client_pages, @clients = paginate :clients, :per_page => 10
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
      flash[:notice] = 'Client was successfully created.'
      redirect_to :action => 'clientlist'
    else
      render :action => 'newclient'
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
      flash[:notice] = 'Client was successfully updated.'
      redirect_to :action => 'listClient', :id => @client
    else
      render :action => 'editClient'
    end
  end
  
  # Deletes the chosen client
  def destroyClient
    Client.find(params[:id]).destroy
    redirect_to :action => 'clientlist'
  end
end
