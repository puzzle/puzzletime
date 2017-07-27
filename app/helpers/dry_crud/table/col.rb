#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module DryCrud::Table
  # Helper class to store column information.
  class Col < Struct.new(:header, :html_options, :template, :block) #:nodoc:
    delegate :content_tag, :capture, to: :template

    # Runs the Col block for the given entry.
    def content(entry)
      entry.nil? ? '' : capture(entry, &block)
    end

    # Renders the header cell of the Col.
    def html_header
      content_tag(:th, header, html_options)
    end

    # Renders a table cell for the given entry.
    def html_cell(entry)
      content_tag(:td, content(entry), html_options)
    end
  end
end
