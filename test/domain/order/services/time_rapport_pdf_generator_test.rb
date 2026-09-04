# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require 'test_helper'

class Order
  module Services
    class TimeRapportPdfGeneratorTest < ActiveSupport::TestCase
      COLUMN_HEADERS = {
        date: 'Datum', hours: 'Stunden', from: 'Von', to: 'Bis',
        member: 'Member', accounting_post: 'Buchungsposition', ticket: 'Ticket', remarks: 'Bemerkungen'
      }.freeze

      test 'column_widths is not empty when columns are active' do
        # Regression test for a bug where the fixed widths were keyed by column
        # *index* but looked up by column *name*, so column_widths always
        # returned {} and Prawn silently fell back to its own auto-layout.
        widths = column_widths_for(start_stop: 'true', show_work_item: 'true', show_ticket: 'true', description: 'true')

        assert_not_empty widths
      end

      test 'no active column is narrower than its own header text, with all optional columns enabled' do
        assert_headers_fit(start_stop: 'true', show_work_item: 'true', show_ticket: 'true', description: 'true')
      end

      test 'no active column is narrower than its own header text, with no optional columns enabled' do
        assert_headers_fit({})
      end

      test 'columns use up the full available table width' do
        pdf, widths = build_pdf_and_widths(start_stop: 'true', show_work_item: 'true', show_ticket: 'true', description: 'true')

        assert_in_delta pdf.bounds.width, widths.values.sum, 1.0
      end

      test 'disabling optional columns does not widen the remaining fixed columns' do
        column_map, widths_all = column_map_and_widths_for(start_stop: 'true', show_work_item: 'true', show_ticket: 'true',
                                                           description: 'true')
        _, widths_minimal = column_map_and_widths_for({})

        %i[date hours].each do |key|
          assert_in_delta widths_all[column_map[key]], widths_minimal[column_map[key]], 0.01,
                          "#{key} column width must not depend on how many optional columns are enabled"
        end
      end

      private

      def assert_headers_fit(params)
        column_map, widths = column_map_and_widths_for(params)
        pdf = build_pdf

        COLUMN_HEADERS.each do |key, text|
          index = column_map[key]
          next unless index

          header_width = pdf.width_of(text, style: :bold)

          assert_operator widths[index], :>=, header_width - 0.01,
                          "#{key} column (#{widths[index]}) is narrower than its header '#{text}' (#{header_width})"
        end
      end

      def column_widths_for(params)
        _, widths = column_map_and_widths_for(params)
        widths
      end

      def column_map_and_widths_for(params)
        _pdf, widths = build_pdf_and_widths(params)
        [@last_column_map, widths]
      end

      def build_pdf_and_widths(params)
        generator = build_generator(params)
        pdf = build_pdf

        generator.send(:worktimes_table_rows)
        @last_column_map = generator.instance_variable_get(:@column_map)
        [pdf, generator.send(:column_widths, pdf)]
      end

      def build_pdf
        pdf = Prawn::Document.new(margin: [90, 30, 70, 30], page_layout: :portrait, page_size: 'A4')
        pdf.font_size = 8
        pdf
      end

      def build_generator(params)
        data = Order::Services::TimeRapportData.new(
          order: orders(:puzzletime),
          worktimes: [worktimes(:wt_pz_puzzletime)],
          tickets: [],
          ticket_view: false,
          employees: [employees(:pascal)],
          employee: nil,
          work_items: [work_items(:puzzletime)],
          period: Period.new(nil, nil)
        )
        Order::Services::TimeRapportPdfGenerator.new(data, params)
      end
    end
  end
end
