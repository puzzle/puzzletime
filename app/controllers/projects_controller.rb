# encoding: utf-8

# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

# TODO: set client/parent when creating project
class ProjectsController < ManageController

  include ProjectGroupable

  self.permitted_attrs = [:name, :shortname, :description, :client_id, :offered_hours, :offered_rate,
                          :discount, :portfolio_item_id, :reference, :billable, :closed,
                          :freeze_until, :report_type, :description_required, :ticket_required]

  self.search_columns = [:path_shortnames, :path_names, :inherited_description]

  before_action :authorize, only: [:edit, :update, :destroy]

  def search
    params[:q] ||= params[:term]
    respond_to do |format|
      format.json do
        @projects = Project.list.
                            where(leaf: true).
                            where(search_conditions).
                            select(:id, :name, :path_shortnames, :inherited_description).
                            limit(20)
      end
    end
  end

  private

  def list_entries
    if group
      super.merge(group_filter)
    else
      managed_projects
    end
  end

  def managed_projects
    @user.managed_projects.page(params[:page])
  end

  def authorized?
    super || managed_project?(entry)
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
