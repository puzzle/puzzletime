#
# client controllers must implement modelClass, editFields
# and may implement groupClass, listFields, listActions, formatColumn, initFormData
# 
# models must extend Manageable and implement self.labels (see Manageable)
module ManageModule

  def self.included(controller)
    controller.helper :manage  
    controller.helper_method :group, :modelClass, :formatColumn, :listFields, :editFields
   
    # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
    controller.verify :method => :post, :only => [ :create, :update, :delete ],
         :redirect_to => { :action => :list }
         
    controller.hide_action :modelClass, :groupClass, :group, :formatColumn,
                           :editFields, :listFields, :listActions
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
    renderManage :action => 'list'                      
  end
    
  def add
    @entry = modelClass.new
    initFormData
    renderManage :action => 'add'
  end
  
  def create
    @entry = modelClass.new(params[:entry])
    @entry.send("#{groupClass.to_s.downcase}_id=".to_sym, params[:group_id]) if group?
    if @entry.save
      flash[:notice] = classLabel + ' wurde erfasst'
      redirectToList
    else
      initFormData
      renderManage :action => 'add'
    end
  end
  
  def edit
    setEntryFromId
    initFormData
    renderManage :action => 'edit'
  end
  
  def update
    setEntryFromId
    if @entry.update_attributes(params[:entry])
      flash[:notice] = classLabel + ' wurde aktualisiert'
      redirectToList
    else      
      flash[:notice] = classLabel + ' konnte nicht aktualisiert werden'
      initFormData
      renderManage :action => 'edit'
    end
  end
  
  def confirmDelete
    setEntryFromId
    renderManage :action => 'confirmDelete' 
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
  
  ####### helper methods, not actions ##########
  
  def listActions
    []
  end
  
  def listFields
    editFields
  end
  
  # must overwrite in mixin class 
  def editFields
    []
  end
    
  def group
    groupClass.find(params[:group_id]) if group?
  end
  
  def formatColumn(attribute, value)    
    case modelClass.columnType(attribute)
      when :date then value.strftime(LONG_DATE_FORMAT) if value
      when :float then "%01.2f" % value if value
      when :integer then value
      when :boolean then value ? 'ja' : 'nein'
      else value.to_s
      end
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
  
  def renderManage(options)
    template = options[:action]
    if template && ! template_exists?("#{self.class.controller_path}/#{template}")
      options[:action] = "../manage/#{template}"
    end    
    render options  
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