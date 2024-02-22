# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module DryCrud
  module Table
    # A simple helper to easily define tables listing several rows of the same
    # data type.
    #
    # Example Usage:
    #   DryCrud::Table::Builder.table(entries, template) do |t|
    #     t.col('My Header', class: 'css') {|e| link_to 'Show', e }
    #     t.attrs :name, :city
    #   end
    class Builder
      include Sorting
      include Actions

      attr_reader :entries, :cols, :options, :template

      delegate :content_tag, :format_attr, :column_type, :association, :dom_id,
               :captionize, :add_css_class, :content_tag_nested,
               to: :template

      def initialize(entries, template, options = {})
        @entries = entries
        @template = template
        @options = options
        @footer = nil
        @cols = []
      end

      # Convenience method to directly generate a table. Renders a row for each
      # entry in entries. Takes a block that gets the table object as parameter
      # for configuration. Returns the generated html for the table.
      def self.table(entries, template, options = {})
        t = new(entries, template, options)
        yield t
        t.to_html
      end

      # Define a column for the table with the given header, the html_options
      # used for each td and a block rendering the contents of a cell for the
      # current entry. The columns appear in the order they are defined.
      def col(header = '', html_options = {}, &block)
        @cols << Col.new(header, html_options, @template, block)
      end

      # Convenience method to add one or more attribute columns.
      # The attribute name will become the header, the cells will contain
      # the formatted attribute value for the current entry.
      def attrs(*attrs)
        attrs.each do |a|
          attr(a)
        end
      end

      # Define a column for the given attribute and an optional header.
      # If no header is given, the attribute name is used. The cell will
      # contain the formatted attribute value for the current entry.
      def attr(a, header = nil, html_options = {}, &block)
        header ||= attr_header(a)
        block ||= ->(e) { format_attr(e, a) }
        add_css_class(html_options, align_class(a))
        col(header, html_options, &block)
      end

      def row_attrs(&block)
        @row_attrs = block
      end

      # Renders the table as HTML.
      def to_html
        content_tag :table, options do
          content_tag(:thead, html_header) +
            content_tag_nested(:tbody, entries) { |e| html_row(e) } +
            (@footer ? content_tag(:tfoot, @footer) : '')
        end
      end

      # Returns css classes used for alignment of the cell data.
      # Based on the column type of the attribute.
      def align_class(attr)
        entry = entries.present? ? entry_class.new : nil
        case column_type(entry, attr)
        when :integer, :float, :decimal, :date, :time, :datetime, :timestamp
          'text-right' unless association(entry, attr, :belongs_to)
        when :boolean
          'text-center'
        end
      end

      # Creates a header string for the given attr.
      def attr_header(attr)
        captionize(attr, entry_class)
      end

      # Create a table footer with arbitrary html
      def foot(&)
        @footer = template.capture(entries, &)
      end

      private

      # Renders the header row of the table.
      def html_header
        content_tag_nested(:tr, cols, &:html_header)
      end

      # Renders a table row for the given entry.
      def html_row(entry)
        attrs = @row_attrs ? @row_attrs.call(entry) : {}
        attrs[:id] ||= dom_id(entry) if entry.respond_to?(:to_key)
        content_tag_nested(:tr, cols, attrs) { |c| c.html_cell(entry, options[:responsive]) }
      end

      # Determines the class of the table entries.
      # All entries should be of the same type.
      def entry_class
        if entries.respond_to?(:klass)
          entries.klass
        else
          entries.first.class
        end
      end
    end
  end
end
