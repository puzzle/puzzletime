# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Order
  module Services
    class TimeRapportPdfGenerator
      attr_reader :order, :params

      def initialize(order, worktimes, work_items, period, params = {})
        @order = order
        @worktimes = worktimes
        @work_items = work_items
        @period = period
        @params = params
      end

      def generate_pdf
        compose_pdf_report
      end

      private

      def compose_pdf_report
        pdf = Prawn::Document.new(margin: [90, 60, 70, 60])
        pdf.font_size = 8.5
        pdf.font_families.update(
          'Roboto' => {
            normal: Rails.root.join('app/assets/fonts/Roboto-Regular.ttf'),
            italic: Rails.root.join('app/assets/fonts/Roboto-Italic.ttf'),
            bold: Rails.root.join('app/assets/fonts/Roboto-Bold.ttf'),
            bold_italic: Rails.root.join('app/assets/fonts/Roboto-BoldItalic.ttf')
          }
        )
        pdf.font 'Roboto'
        build_footer(build_list(build_information_section(build_header(pdf))))
      end

      def build_header(pdf)
        pdf.repeat(:all) do
          pdf.image Rails.root.join('app/assets/images', Company.logo_path).to_s, at: [pdf.bounds.right - 130, pdf.bounds.top + 60], width: 130, position: :right if Company.logo_path.present?
        end
        pdf
      end

      def build_information_section(pdf)
        customer_data = [
          ['Kunde', @work_items[0].top_item.client.label],
          ['Auftrag', 'order_number'],
          ['Periode', @period.to_s],
          ['Verrechenbar', params[:billable].present? ? t("global.#{params[:billable]}") : 'Alle']
        ]

        # Draw customer/order/time info as a table
        pdf.move_down 20
        pdf.text "Zeitrapport #{Company.name}", size: 18, style: :bold
        pdf.move_down 20 # Space before table

        pdf.table(customer_data, header: false, cell_style: { padding: 4, border_width: 0.3 }, width: pdf.bounds.width * 0.6) do

          # Adjust alignment for columns
          column(0).align = :left  # Left-aligned labels (Customer, Order Number, etc.)
          column(1).align = :left  # Left-aligned values
          
          cells.borders = [:bottom, :top] # Only horizontal lines
          cells.border_color = 'dddddd'

          (0..row_length - 1).each do |index|
            cells[index, 0].font_style = :bold
          end
        end
        pdf.move_down 20
        pdf
      end

      # Builds the table rows as string list according to the passed params
      def table_rows
        # Define table headers
        data = [%w[Datum Member Stunden Buchungsposition]]

        # Add table rows
        @worktimes.each do |w|
          data << [w.date_string, w.employee.to_s, format('%.2f', w.hours), w.work_item.to_s]
        end
        data
      end

      def build_list(pdf)
        pdf.table(table_rows, header: true, cell_style: { padding: 4, border_width: 0.3 }, width: pdf.bounds.width) do
          row(0).font_style = :bold
          row(0).background_color = 'f0f0f0'  # Light gray
          row(0).text_color = '333333'        # Dark gray

          (1..row_length - 1).each do |index|
            row(index).background_color = index.even? ? 'f0f0f0' : 'ffffff'
          end

          column(2).align = :right # Right-align hours

          cells.borders = [:bottom] # Only horizontal lines
          cells.border_color = 'dddddd' # Light gray borders
        end

        pdf
      end

      def build_footer(pdf)
        string = '<page>/<total>'
        options = {
          at: [pdf.bounds.right - 150, pdf.bounds.bottom - 38],
          width: 150,
          align: :right,
          page_filter: :all,
          start_count_at: 1,
          size: 8
        }
        pdf.number_pages string, options
        # Footer Section
        pdf.repeat(:all) do
          pdf.draw_text 'Puzzle ITC AG', at: [pdf.bounds.left, pdf.bounds.bottom - 20], size: 8, style: :bold
          pdf.draw_text 'Belpstrasse 37, CH-3007 Bern', at: [pdf.bounds.left, pdf.bounds.bottom - 29], size: 8
          pdf.draw_text '+41 31 370 22 00 / www.puzzle.ch', at: [pdf.bounds.left, pdf.bounds.bottom - 38], size: 8
        end
        pdf
      end
    end
  end
end
