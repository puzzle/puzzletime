class AdminWorktimeControllerController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @worktime_pages, @worktimes = paginate :worktimes, :per_page => 10
  end

  def show
    @worktime = Worktime.find(params[:id])
  end

  def new
    @worktime = Worktime.new
  end

  def create
    @worktime = Worktime.new(params[:worktime])
    if @worktime.save
      flash[:notice] = 'Worktime was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @worktime = Worktime.find(params[:id])
  end

  def update
    @worktime = Worktime.find(params[:id])
    if @worktime.update_attributes(params[:worktime])
      flash[:notice] = 'Worktime was successfully updated.'
      redirect_to :action => 'show', :id => @worktime
    else
      render :action => 'edit'
    end
  end

  def destroy
    Worktime.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
