module SortHelper
  def sort_link(attr, label = nil, options = {})
    label ||= entry.class.human_attribute_name(attr)
    link_to(label, sort_params(attr, options)) + current_mark(attr, options)
  end

  private

  # Request params for the sort link.
  def sort_params(attr, options)
    params.merge(sort: attr, sort_dir: sort_dir(attr, options))
  end

  # The sort mark, if any, for the given attribute.
  def current_mark(attr, options)
    if current_sort?(attr, options)
      (sort_dir(attr, options) == 'asc' ? ' &uarr;' : ' &darr;').html_safe
    else
      ''
    end
  end

  # Returns true if the given attribute is the current sort column.
  def current_sort?(attr, options)
    params[:sort] == attr.to_s || (options[:default] && !params[:sort])
  end

  # The sort direction to use in the sort link for the given attribute.
  def sort_dir(attr, options)
    if current_sort?(attr, options) && (params[:sort_dir] || options[:default_dir]) == 'asc'
      'desc'
    else
      'asc'
    end
  end
end
