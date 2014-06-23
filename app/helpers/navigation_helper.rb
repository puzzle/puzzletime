module NavigationHelper

  # Create a list item for navigations.
  # If active_for are given, and they appear in the request url,
  # the corresponding item is active.
  # If no active_for are given, the item is only active if the
  # link url equals the request url.
  def nav(label, url, *active_for)
    options = {}
    if current_page?(url) ||
       active_for.any? { |p| request.path =~ %r{^#{p}(/.*)?$} }
      options[:class] = 'active'
    end
    content_tag(:li, link_to(label, url), options)
  end
end