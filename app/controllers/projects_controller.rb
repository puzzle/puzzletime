# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

class ProjectsController < CrudController

  include ProjectGroupable

  self.permitted_attrs = [:description, :report_type, :offered_hours, :billable,
                          :freeze_until, :description_required, :ticket_required]

  # Checks if employee came from login or from direct url.
  before_action :authenticate
  before_action :authorize, only: [:destroy]

  after_create :set_project_manager


  # TODO: remove?
  def list_sub_projects
    list
  end

  private

  def list_entries
    if group
      super.merge(group_filter)
    else
      managed_projects
    end
  end

  def set_project_manager
    Projectmembership.create(project_id: @entry.id,
                             employee_id: @user.id,
                             projectmanagement: true)
  end

  def managed_projects
    @user.managed_projects.page(params[:page])
  end

  def authorize
    authenticate
    project = Project.find(params[:id])
    super unless managed_project?(project)
  end

  def managed_project?(project)
    (@user.managed_projects.collect { |p| p.id } & project.path_ids).present?
  end

  def group_filter
    if group.is_a?(Project)
      Project.where(parent_id: group.id)
    else
      Project.where(parent_id: nil, group_key => group.id)
    end
  end

  def group_key
    @group_key ||= group.class.model_name.param_key
  end

  def path_args(last)
    [main_group, group, last].compact.uniq
  end

end
