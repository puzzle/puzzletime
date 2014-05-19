# ManageController may be extended by other Controllers that want to provide
# management functionality for their represented objects. This includes listing,
# creating, updating and deleting entries.
#
# The class of the managed objects is called a Model. Several managed objects can belong to
# a certain group, e.g., projects belong to one client.
#
# Client controllers must implement model_class, edit_fields
# and may implement group_class, list_fields, list_actions, format_column, init_form_data
#
# Models must extend Manageable and implement self.labels (see Manageable)
class ManageController < ApplicationController

  helper :manage
  helper_method :group, :model_class, :format_column,
                :list_fields, :edit_fields, :group_parent_id, :group_label, :local_group_key

  before_action :authorize

  hide_action :model_class, :group_class, :group, :format_column,
              :edit_fields, :list_fields, :list_actions,
              :group_id_field, :group_parent_id, :group_label

  VALID_GROUPS = []

  # Main Action. Redirects to list.
  def index
    redirect_to_list
  end

  # Action to list all available entries from the database.
  def list
    @entries = model_class.list(conditions: conditions).page(params[:page])
    render action: 'list'
  end

  # Action to add a new entry.
  def add
    @entry = model_class.new
    init_form_data
    render action: 'add'
  end

  # Action to create an added entry in the database.
  def create
    @entry = model_class.new(params[:entry])
    @entry.send("#{group_id_field}=".to_sym, group_id) if group?
    if @entry.save
      flash[:notice] = class_label + ' wurde erfasst'
      redirect_to_list
    else
      init_form_data
      render action: 'add'
    end
  end

  # Action to edit an entry.
  def edit
    set_entry_from_id
    init_form_data
    render action: 'edit'
  end

  # Action to update an edited entry in the database.
  def update
    set_entry_from_id
    if @entry.update_attributes(params[:entry])
      flash[:notice] = class_label + ' wurde aktualisiert'
      redirect_to_list
    else
      flash[:notice] = class_label + ' konnte nicht aktualisiert werden'
      init_form_data
      render action: 'edit'
    end
  end

  # Action to confirm the deletion of an entry.
  def confirm_delete
    set_entry_from_id
    render action: 'confirm_delete'
  end

  # Action to delete an entry from the database.
  def delete
    begin
      model_class.destroy(params[:id])
      flash[:notice] = class_label + ' wurde entfernt'
   rescue => err
      flash[:notice] = err.message
    end
    redirect_to_list
  end

  def synchronize
    mapper = model_class.puzzlebase_map
    flash[:notice] = model_class.label_plural + ' wurden nicht aktualisiert'
    redirect_to_list if mapper.nil?
    @errors = mapper.synchronize
    if @errors.empty?
      flash[:notice] = model_class.label_plural + ' wurden erfolgreich aktualisiert'
      redirect_to_list
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
  def model_class
    self.class.model_class
  end

  def local_group_key
    self.class::GROUP_KEY
  end

  # Links that appear for each entry in the list action.
  # Returns an Array of 4-element Arrays with the following elements:
  # [label, controller, action, is_displayed_method]
  # Every created link holds the id of the entry as parameter.
  def list_actions
    []
  end

  # The fields of an entry object that are displayed in the list action.
  # Defaults to all editable fields.
  def list_fields
    edit_fields
  end

  # The fields of an entry object that may be edited.
  # Must overwrite in mixin class.
  def edit_fields
    []
  end

  # The group entry for the currently active entry.
  # This object is determined over the parameter group_id.
  def group
    group_class.find(group_id) if group?
  end

  # Formats the value for the field attribute.
  def format_column(attribute, value, entry)
    case model_class.column_type(attribute)
      when :date then value.strftime(LONG_DATE_FORMAT) if value
      when :float, :decimal then '%01.2f' % value if value
      when :integer then value
      when :boolean then value ? 'ja' : 'nein'
      else value.to_s
      end
  end

  # Label for the group overview link
  def group_label
    group_class.label_plural
  end

  protected

  # The group class the represented entry objects belong to.
  # E.g., the group of a Project is a Client. Default is nil.
  def group_class
    ctrlr = self.class::VALID_GROUPS.find { |c| c::GROUP_KEY == group_key }
    ctrlr.model_class if ctrlr
  end

  # Initializes the data for editing an entry.
  # Is currently used to set default values.
  def init_form_data
  end

  # SQL WHERE conditions for the entries displayed in the list action.
  # May return nil.
  def conditions
    ["#{group_id_field} = ?", group_id] if group?
  end

  def group_id_field
    "#{group_class.to_s.downcase}_id"
  end

  def group_key
    last_param :groups
  end

  def group_id
    last_param :group_ids
  end

  private

  # Sets the instance variable entry from the HTTP parameter.
  def set_entry_from_id
    @entry = model_class.find(params[:id])
  end

  # Redirects a request to the list action.
  def redirect_to_list
    redirect_to action: 'list',
                page: params[:page],
                groups: params[:groups],
                group_ids: params[:group_ids],
                group_pages: params[:group_pages]
  end

  # Label with article of the model class.
  def class_label
    model_class.article + ' ' + model_class.label
  end

  # Returns whether a group is defined for the current request.
  def group?
    group_class && group_id
  end

  def last_param(key)
    params[key].split('-').last if params[key]
  end

end
