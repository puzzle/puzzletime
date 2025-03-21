# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Order
  module Services
    class TimeRapportPdfGenerator
      attr_reader :order, :params

      def initialize(order, worktimes, work_items, params = {})
        @order = order
        @worktimes = worktimes
        @work_items = work_items
        @params = params
      end

      def generate_pdf
        compose_pdf_report
      end

      private

      def compose_pdf_report
        pdf = Prawn::Document.new
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
        pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width) do
          pdf.text 'Zeitrapport', size: 18, style: :bold, align: :center
          pdf.move_down 10
          pdf.text Company.name, size: 12, style: :bold, align: :center
          pdf.text "Address, Contact Info, Website", size: 10, align: :center
          pdf.move_down 20  # Space before table
        end
        pdf
      end

      def build_information_section(pdf)
        customer_data = [
          ['Kunde', @work_items[0].top_item.client.label],
          ['Auftrag', 'order_number'],
          ['Periode', "XX to XX"],
          ['Verrechenbar', "XX to XX"]
        ]

        # Draw customer/order/time info as a table
        pdf.bounding_box([30, pdf.cursor], width: pdf.bounds.width - 60) do
          pdf.table(customer_data, header: false, cell_style: { padding: 4, border_width: 0.3 }, width: pdf.bounds.width / 3) do

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
        end
        pdf
      end

      def build_footer(pdf)
        pdf.move_down 20  # Add some space before footer

        # Footer Section
        pdf.bounding_box([0, pdf.bounds.bottom + 20], width: pdf.bounds.width) do
          pdf.text "Company Name", size: 10, align: :center
          pdf.text "Address | Email | Phone", size: 8, align: :center
          pdf.text "Page: #{pdf.page_number}", size: 8, align: :center
        end
        pdf
      end
      # Builds the table rows as string list according to the passed params
      def build_pdf_table_rows
        # TODO:
      end

      def build_list(pdf)
        # Define table headers
        data = [%w[Datum Member Stunden Buchungsposition]]

        # Add table rows
        @worktimes.each do |w|
          data << [w.date_string, w.employee.to_s, w.hours.to_s, w.work_item.to_s]
        end

        pdf.bounding_box([30, pdf.cursor], width: pdf.bounds.width - 60) do
          pdf.table(data, header: true, cell_style: { padding: 4, border_width: 0.3 }, width: pdf.bounds.width) do
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
        end

        pdf
      end
    end
  end
end
