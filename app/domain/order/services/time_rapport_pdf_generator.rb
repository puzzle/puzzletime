# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Order
  module Services
    class TimeRapportPdfGenerator
      attr_reader :order, :params

      def initialize(order, worktimes, params = {})
        @order = order
        @worktimes = worktimes
        @params = params
      end

      def generate_pdf
        build_report
      end

      private

      # Builds the table rows as string list according to the passed params
      def build_pdf_table_rows
        # TODO:
      end

      def build_report
        pdf = Prawn::Document.new
        pdf.font_size = 10
        pdf.font_families.update(
          'Roboto' => {
            normal: Rails.root.join('app/assets/fonts/Roboto-Regular.ttf'),
            italic: Rails.root.join('app/assets/fonts/Roboto-Italic.ttf'),
            bold: Rails.root.join('app/assets/fonts/Roboto-Bold.ttf'),
            bold_italic: Rails.root.join('app/assets/fonts/Roboto-BoldItalic.ttf')
          }
        )
        pdf.font 'Roboto'

        # Define table headers
        data = [%w[Datum Member Stunden Buchungsposition]]

        # Add table rows
        @worktimes.each do |w|
          data << [w.date_string, w.employee.to_s, w.hours.to_s, w.work_item.to_s]
        end

        # Create table with improved styling
        pdf.table(data, header: true, cell_style: { padding: 4, border_width: 0.3 }, width: pdf.bounds.width) do
          # HEADER STYLE
          row(0).font_style = :bold
          row(0).background_color = 'f5f5f5'  # Light gray
          row(0).text_color = '333333'        # Dark gray
          row(0).size = 11                    # Slightly larger font

          # ALTERNATING ROW COLORS
          (1..row_length - 1).each do |index|
            row(index).background_color = index.odd? ? 'f0f0f0' : 'ffffff'
          end

          # ALIGNMENT
          column(2).align = :right # Right-align hours

          # COLUMN WIDTHS
          self.column_widths = column_widths

          # BORDER STYLING
          cells.borders = [:bottom] # Only horizontal lines
          cells.border_color = 'dddddd' # Light gray borders
        end

        pdf
      end
    end
  end
end
