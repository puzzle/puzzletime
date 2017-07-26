# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module SortHelper
  def sort_link(attr, label = nil, options = {})
    label ||= entry.class.human_attribute_name(attr)
    link_to(label, sort_params(attr, options)) + current_mark(attr, options)
  end

  private

  # Request params for the sort link.
  def sort_params(attr, options = {})
    result = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params
    result.merge(sort: attr, sort_dir: sort_dir(attr, options), only_path: true)
  end

  # The sort mark, if any, for the given attribute.
  def current_mark(attr, options = {})
    if current_sort?(attr, options)
      (sort_dir(attr, options) == 'asc' ? ' &uarr;' : ' &darr;').html_safe
    else
      ''
    end
  end

  # Returns true if the given attribute is the current sort column.
  def current_sort?(attr, options = {})
    params[:sort] == attr.to_s || (options[:default] && !params[:sort])
  end

  # The sort direction to use in the sort link for the given attribute.
  def sort_dir(attr, options = {})
    if current_sort?(attr, options) && (params[:sort_dir] || options[:default_dir]) == 'asc'
      'desc'
    else
      'asc'
    end
  end
end
