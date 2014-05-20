# encoding: utf-8

module ProjectsHelper

  def format_project_name(project)
    project.label_verbose
  end

  def sub_projects_path(project)
    case main_group
    when Project then project_projects_path(project)
    when Client then client_project_projects_path(main_group, project)
    when Department then department_project_projects_path(main_group, project)
    end
  end

  def group_projects_link(current = group)
    if main_group == current
      main_group_link
    elsif current.parent_id.nil?
      main_projects_link
    else
      main_sub_projects_link(current.parent)
    end
  end

  def projects_title
    title = @project ? full_entry_label : models_label(true)
    if group
      title << " von #{h(@group)}".html_safe
    end
    title
  end

  def project_breadcrumb
    return if main_group == group
    breadcrumb = []
    unless main_group.is_a?(Project)
      breadcrumb << link_to(main_group, main_projects_path)
    end

    path = group.ancestor_projects
    path << group if @project
    path.each do |p|
      breadcrumb << link_to(p, main_sub_projects_path(p.id))
    end
    safe_join(breadcrumb, ' &gt; '.html_safe)
  end

  private

  def main_group_link
    klass = main_group.class
    link_to("Übersicht #{klass.model_name.human(count: 2)}",
            polymorphic_path(klass, returning: true))
  end

  def main_projects_link
    link_to("Übersicht #{main_group}",
            main_projects_path)
  end

  def main_projects_path
    send("#{main_group.class.model_name.param_key}_projects_path", main_group, returning: true)
  end

  def main_sub_projects_link(current)
    link_to("Übersicht #{current}",
            main_sub_projects_path(current.id))
  end

  def main_sub_projects_path(id)
    case main_group
    when Project then project_projects_path(id, returning: true)
    when Client then client_project_projects_path(main_group, id, returning: true)
    when Department then department_project_projects_path(main_group, id, returning: true)
    end
  end

end