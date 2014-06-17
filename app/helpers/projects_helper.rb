# encoding: utf-8

module ProjectsHelper

  def format_project_name(project)
    project.label_verbose
  end

  def projects_title
    title = group.kind_of?(Project) ? 'Subprojekte' : 'Projekte'
    if group
      title << " von #{h(@group)}".html_safe
    end
    title
  end

  def sub_projects_path(project)
    case main_group
    when nil, Project then project_projects_path(project)
    when Client then client_project_projects_path(main_group, project)
    when Department then department_project_projects_path(main_group, project)
    end
  end

  def project_memberships_path(project)
    case main_group
    when nil, Project then project_project_memberships_path(project)
    when Client then client_project_project_memberships_path(main_group, project)
    when Department then department_project_project_memberships_path(main_group, project)
    end
  end

  def group_projects_link(current = group)
    if main_group == current && (!main_group.is_a?(Project) || main_group.parent_id.nil?)
      main_group_link
    elsif main_group.nil?
      link_to("Übersicht Projekte", projects_path(returning: true))
    elsif current.parent_id.nil?
      main_projects_link
    else
      main_sub_projects_link(current.parent)
    end
  end

  def project_breadcrumb
    return if main_group == group && !main_group.is_a?(Project)
    breadcrumb = []
    unless main_group.is_a?(Project)
      breadcrumb << link_to(main_group, main_projects_path)
    end

    path_ids = group.path_ids[0..-2]
    path_ids << group.id if @project
    path_ids.each_with_index do |id, i|
      breadcrumb << link_to(group.path_names.split("\n")[i+1], main_sub_projects_path(id))
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