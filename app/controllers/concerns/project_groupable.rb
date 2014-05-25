# encoding: utf-8

module ProjectGroupable
  extend ActiveSupport::Concern

  VALID_GROUPS = [Client, Department, Project]

  included do
    helper_method :group, :main_group
  end

  private

  def group
    @group ||=
      begin
        project_id = params[:project_id].presence
        if project_id && !(main_group.is_a?(Project) && main_group.id == project_id)
          Project.find(project_id)
        else
          main_group
        end
      end
  end

  def main_group
    @main_group ||= main_group_model && main_group_model.find(group_param(main_group_model))
  end

  def main_group_model
    @main_group_model ||= VALID_GROUPS.detect { |m| group_param(m).present? }
  end

  def group_param(model)
    params["#{model.model_name.param_key}_id"]
  end

end
