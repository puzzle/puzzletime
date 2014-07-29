module SortHelper

  def sort_link(attr, label = nil)
    label ||= entry.class.human_attribute_name(attr)
    link_to(label, sort_params(attr)) + current_mark(attr)
  end

  private

  # Request params for the sort link.
  def sort_params(attr)
    params.merge(sort: attr, sort_dir: sort_dir(attr))
  end

  # The sort mark, if any, for the given attribute.
  def current_mark(attr)
    if current_sort?(attr)
      (sort_dir(attr) == 'asc' ? ' &uarr;' : ' &darr;').html_safe
    else
      ''
    end
  end

  # Returns true if the given attribute is the current sort column.
  def current_sort?(attr)
    params[:sort] == attr.to_s
  end

  # The sort direction to use in the sort link for the given attribute.
  def sort_dir(attr)
    current_sort?(attr) && params[:sort_dir] == 'asc' ? 'desc' : 'asc'
  end

end