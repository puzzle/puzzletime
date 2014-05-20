# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class ProjectController < ManageController

  include Conditioner

  # Checks if employee came from login or from direct url.
  before_action :authenticate
  before_action :authorize, only: [:delete, :confirm_delete]

  VALID_GROUPS = [ClientController, DepartmentController, ProjectController]
  GROUP_KEY = 'project'

  def list
    # nana, list managed projects for everybody
    # if @user.management? then super
    # else list_managed_projects
    # end
    group? ? super : list_managed_projects
  end

  def list_managed_projects
    @entries = @user.managed_projects.page(params[:page])
    render action: 'list'
  end

  def list_sub_projects
    list
  end

  def create
    super
    if @entry.errors.empty?
      # set current user as project manager
      Projectmembership.create(project_id: @entry.id,
                               employee_id: @user.id,
                               projectmanagement: true)
    end
  end

  ####### helper methods, not actions ##########

  def model_class
    Project
  end

  def list_actions
    [['Subprojekte', 'project', 'list', :children?],
     ['Mitarbeiter', 'projectmembership', 'list_employees', true]]
  end

  def list_fields
    [[:name, 'Name'],
     [:description, 'Beschreibung']]
  end

  def edit_fields
    [[:description, 'Beschreibung'],
     [:report_type, 'Reporttyp'],
     [:offered_hours, 'Offerierte Stunden'],
     [:billable, 'Verrechenbar'],
     [:freeze_until, 'Eingefroren vor'],
     [:description_required, 'Beschreibung nötig'],
     [:ticket_required, 'Ticket/Task nötig']]
  end

  def format_column(attribute, value, entry)
    return entry.label_verbose if attribute == :name
    super attribute, value, entry
  end

  def authorize
    authenticate
    project = Project.find(params[:id])
    if (@user.managed_projects.collect { |p| p.id } & project.path_ids).empty?
      super
    end
  end

  def group_label
    sub_sub_project? ? 'Übergeordnetes Projekt' : super
  end

  protected

  def conditions
    sub_projects? ? ['parent_id = ?', group_id] : append_conditions(super, ['parent_id IS NULL'])
  end

  private

  def sub_projects?
    group_class == model_class
  end

  def sub_sub_project?
    params[:groups] &&
    params[:groups].size > 2 &&
    params[:groups][-2] == group_key &&
    params[:groups][-3] == group_key
  end

end
