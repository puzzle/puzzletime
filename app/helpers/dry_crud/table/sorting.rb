#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module DryCrud::Table
  # Provides headers with sort links. Expects a method :sortable?(attr)
  # in the template/controller to tell if an attribute is sortable or not.
  # Extracted into an own module for convenience.
  module Sorting
    # Create a header with sort links and a mark for the current sort
    # direction.
    def sort_header(attr, label = nil)
      label ||= attr_header(attr)
      template.sort_link(attr, label)
    end

    # Same as :attrs, except that it renders a sort link in the header
    # if an attr is sortable.
    def sortable_attrs(*attrs)
      attrs.each { |a| sortable_attr(a) }
    end

    # Renders a sort link header, otherwise similar to :attr.
    def sortable_attr(a, header = nil, html_options = {}, &)
      if template.sortable?(a)
        attr(a, sort_header(a, header), html_options, &)
      else
        attr(a, header, html_options, &)
      end
    end
  end
end
