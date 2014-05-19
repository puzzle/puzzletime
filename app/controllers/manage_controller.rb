# ManageController may be extended by other Controllers that want to provide
# management functionality for their represented objects. This includes listing,
# creating, updating and deleting entries.
#
# The class of the managed objects is called a Model. Several managed objects can belong to
# a certain group, e.g., projects belong to one client.
#
# Client controllers must implement modelClass, editFields
# and may implement groupClass, listFields, listActions, formatColumn, initFormData
#
# Models must extend Manageable and implement self.labels (see Manageable)
class ManageController < ApplicationController

  helper :manage
  helper_method :group, :modelClass, :formatColumn,
                :listFields, :editFields, :group_parent_id, :group_label, :local_group_key

  before_action :authorize

  hide_action :modelClass, :groupClass, :group, :formatColumn,
              :editFields, :listFields, :listActions,
              :group_id_field, :group_parent_id, :group_label

  VALID_GROUPS = []

  # Main Action. Redirects to list.
  def index
    redirectToList
  end

  # Action to list all available entries from the database.
  def list
    @entries = modelClass.list(conditions: conditions).page(params[:page])
    render action: 'list'
  end

  # Action to add a new entry.
  def add
    @entry = modelClass.new
    initFormData
    render action: 'add'
  end

  # Action to create an added entry in the database.
  def create
    @entry = modelClass.new(params[:entry])
    @entry.send("#{group_id_field}=".to_sym, group_id) if group?
    if @entry.save
      flash[:notice] = classLabel + ' wurde erfasst'
      redirectToList
    else
      initFormData
      render action: 'add'
    end
  end

  # Action to edit an entry.
  def edit
    setEntryFromId
    initFormData
    render action: 'edit'
  end

  # Action to update an edited entry in the database.
  def update
    setEntryFromId
    if @entry.update_attributes(params[:entry])
      flash[:notice] = classLabel + ' wurde aktualisiert'
      redirectToList
    else
      flash[:notice] = classLabel + ' konnte nicht aktualisiert werden'
      initFormData
      render action: 'edit'
    end
  end

  # Action to confirm the deletion of an entry.
  def confirmDelete
    setEntryFromId
    render action: 'confirmDelete'
  end

  # Action to delete an entry from the database.
  def delete
    begin
      modelClass.destroy(params[:id])
      flash[:notice] = classLabel + ' wurde entfernt'
   rescue => err
      flash[:notice] = err.message
    end
    redirectToList
  end

  def synchronize
    mapper = modelClass.puzzlebaseMap
    flash[:notice] = modelClass.labelPlural + ' wurden nicht aktualisiert'
    redirectToList if mapper.nil?
    @errors = mapper.synchronize
    if @errors.empty?
      flash[:notice] = modelClass.labelPlural + ' wurden erfolgreich aktualisiert'
      redirectToList
    else
      flash[:notice] = 'Folgende Fehler sind bei der Synchronisation aufgetreten:'
      render action: 'synchronize'
    end
  end

  ####### helper methods, not actions ##########

  def self.model_class
    controller_name.camelize.constantize
  end

  # The Class of the managed entries.
  # This method must be overriden by mixin classes.
  def modelClass
    self.class.model_class
  end

  def local_group_key
    self.class::GROUP_KEY
  end

  # Links that appear for each entry in the list action.
  # Returns an Array of 4-element Arrays with the following elements:
  # [label, controller, action, is_displayed_method]
  # Every created link holds the id of the entry as parameter.
  def listActions
    []
  end

  # The fields of an entry object that are displayed in the list action.
  # Defaults to all editable fields.
  def listFields
    editFields
  end

  # The fields of an entry object that may be edited.
  # Must overwrite in mixin class.
  def editFields
    []
  end

  # The group entry for the currently active entry.
  # This object is determined over the parameter group_id.
  def group
    groupClass.find(group_id) if group?
  end

  # Formats the value for the field attribute.
  def formatColumn(attribute, value, entry)
    case modelClass.columnType(attribute)
      when :date then value.strftime(LONG_DATE_FORMAT) if value
      when :float, :decimal then '%01.2f' % value if value
      when :integer then value
      when :boolean then value ? 'ja' : 'nein'
      else value.to_s
      end
  end

  # Label for the group overview link
  def group_label
    groupClass.labelPlural
  end

  protected

  # The group class the represented entry objects belong to.
  # E.g., the group of a Project is a Client. Default is nil.
  def groupClass
    ctrlr = self.class::VALID_GROUPS.find { |c| c::GROUP_KEY == group_key }
    ctrlr.model_class if ctrlr
  end

  # Initializes the data for editing an entry.
  # Is currently used to set default values.
  def initFormData
  end

  # SQL WHERE conditions for the entries displayed in the list action.
  # May return nil.
  def conditions
    ["#{group_id_field} = ?", group_id] if group?
  end

  def group_id_field
    "#{groupClass.to_s.downcase}_id"
  end

  def group_key
    last_param :groups
  end

  def group_id
    last_param :group_ids
  end

  private

  # Sets the instance variable entry from the HTTP parameter.
  def setEntryFromId
    @entry = modelClass.find(params[:id])
  end

  # Redirects a request to the list action.
  def redirectToList
    redirect_to action: 'list',
                page: params[:page],
                groups: params[:groups],
                group_ids: params[:group_ids],
                group_pages: params[:group_pages]
  end

  # Label with article of the model class.
  def classLabel
    modelClass.article + ' ' + modelClass.label
  end

  # Returns whether a group is defined for the current request.
  def group?
    groupClass && group_id
  end

  def last_param(key)
    params[key].split('-').last if params[key]
  end

end
