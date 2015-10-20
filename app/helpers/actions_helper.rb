# encoding: UTF-8

# Helpers to create action links. This default implementation supports
# regular links with an icon and a label. To change the general style
# of action links, change the method #action_link, e.g. to generate a button.
# The common crud actions show, edit, destroy, index and add are provided here.
module ActionsHelper
  # A generic helper method to create action links.
  # These link could be styled to look like buttons, for example.
  def action_link(label, url = {}, html_options = {})
    add_css_class html_options, 'action'
    link_to(label, url, html_options)
  end

  # Outputs an icon for an action with an optional label.
  def action_icon(icon_key, label = nil)
    html = picon(icon_key)
    html << ' ' << label if label
    html
  end

  # Standard show action to the given path.
  # Uses the current +entry+ if no path is given.
  def show_action_link(path = nil)
    return unless can?(:show, entry)
    path ||= path_args(entry)
    action_link(ti('link.show'), path)
  end

  # Standard edit action to given path.
  # Uses the current +entry+ if no path is given.
  def edit_action_link(path = nil)
    return unless can?(:edit, entry)
    path ||= path_args(entry)
    path = path.is_a?(String) ? path : edit_polymorphic_path(path)
    action_link(action_icon('edit', ti('link.edit')), path)
  end

  # Standard destroy action to the given path.
  # Uses the current +entry+ if no path is given.
  def destroy_action_link(path = nil, disabled = false, disabled_tooltip = nil)
    return unless can?(:delete, entry)
    path ||= path_args(entry)
    disabled ? destroy_action_link_disabled(disabled_tooltip) : destroy_action_link_enabled(path)
  end

  # Standard list action to the given path.
  # Uses the current +model_class+ if no path is given.
  def index_action_link(path = nil, url_options = { returning: true })
    return unless can?(:index, model_class)
    path ||= path_args(model_class)
    path = path.is_a?(String) ? path : polymorphic_path(path, url_options)
    action_link(ti('link.list', model: models_label(true)), path)
  end

  # Standard add action to given path.
  # Uses the current +model_class+ if no path is given.
  def add_action_link(path = nil, url_options = {})
    return unless can?(:new, model_class)
    path ||= path_args(model_class)
    path = path.is_a?(String) ? path : new_polymorphic_path(path, url_options)
    action_link(action_icon('add', ti('link.add')), path)
  end

  private

  def destroy_action_link_enabled(path)
    action_link(action_icon('delete', ti('link.delete')), path,
                data: { confirm: ti(:confirm_delete),
                        method: :delete })
  end

  def destroy_action_link_disabled(disabled_tooltip)
    content_tag(:a, action_icon('delete', ti('link.delete')), class: 'disabled', title: disabled_tooltip)
  end
end
