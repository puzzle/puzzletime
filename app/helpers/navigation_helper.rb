# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module NavigationHelper
  # Create a list item for navigations.
  # If active_for are given, and they appear in the request url,
  # the corresponding item is active.
  # If no active_for are given, the item is only active if the
  # link url equals the request url.
  # Also you can give it an exception url, that let's you ignore
  # a specific url that would otherwise match.
  def nav(label, url, *active_for, except: '')
    options = active_for.extract_options!.merge(data: { turbolinks: false })
    active_class = nav_active_class(url, active_for, except)

    content_tag(
      :li,
      link_to(label, url, options),
      class: active_class
    )
  end

  def model_nav(model)
    return unless can?(:read, model)

    path = polymorphic_path(model)
    nav(model.model_name.human(count: 2), path, path)
  end

  private

  def nav_active_class(url, active_for, except)
    return 'active' if current_page?(url)
    return if current_page?(except)
    return unless active_for.any? { |p| request.path =~ /^#{p}/ }

    'active'
  end
end
