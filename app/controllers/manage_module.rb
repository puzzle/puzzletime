
# client controllers must implement modelClass, listActions
# models must implement list, listFields, fieldNames, label, labelPlural, article
module ManageModule

  def self.included(controller)
    controller.helper :manage  
    controller.helper_method :group, :modelClass
   
    # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
    controller.verify :method => :post, :only => [ :create, :update, :delete ],
         :redirect_to => { :action => :list }
         
    controller.hide_action :modelClass, :groupClass, :group, :listActions
  end     
  
  def index
    redirectToList
  end
  
  def list
    @entry_pages = ActionController::Pagination::Paginator.new(
       self, modelClass.count(:conditions => conditions), NO_OF_OVERVIEW_ROWS, params[:page] )
    @entries = modelClass.list(
                          :conditions => conditions,
                          :limit => @entry_pages.items_per_page,
                          :offset => @entry_pages.current.offset)  
    render :action => '../manage/list'                      
  end
    
  def add
    @entry = modelClass.new
    initFormData
    render :action => '../manage/add'
  end
  
  def create
    @entry = modelClass.new(params[:entry])
    @entry.send("#{groupClass.to_s.downcase}_id=".to_sym, params[:group_id]) if group?
    if @entry.save
      flash[:notice] = classLabel + ' wurde erfasst'
      redirectToList
    else
      initFormData
      render :action => '../manage/add'
    end
  end
  
  def edit
    setEntryFromId
    initFormData
    render :action => '../manage/edit'
  end
  
  def update
    setEntryFromId
    if @entry.update_attributes(params[:entry])
      flash[:notice] = classLabel + ' wurde aktualisiert'
      redirectToList
    else      
      flash[:notice] = classLabel + ' konnte nicht aktualisiert werden'
      initFormData
      render :action => '../manage/edit'
    end
  end
  
  def confirmDelete
    setEntryFromId
    render :action => '../manage/confirmDelete'
  end
  
  def delete
    begin
       modelClass.destroy(params[:id])
       flash[:notice] = classLabel + ' wurde entfernt'
    rescue Exception => err
       flash[:notice] = err.message
    end   
    redirectToList
  end
  
  def listActions
    []
  end
    
  def group
    groupClass.find(params[:group_id]) if group?
  end
  
protected
  
  def groupClass
    nil
  end
  
  def initFormData
  
  end  

private

  def setEntryFromId
    @entry = modelClass.find(params[:id])
  end

  def redirectToList
    redirect_to :action => 'list', 
                :page => params[:page], 
                :group_id => params[:group_id],
                :group_page => params[:group_page]
  end
  
  def classLabel
    modelClass.article + ' ' + modelClass.label
  end
    
  def conditions
    ["#{groupClass.to_s.downcase}_id = ?", params[:group_id]] if group?
  end
  
  def group?
    groupClass && params[:group_id]
  end

end