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
        pdf = Prawn::Document.new(margin: [90, 30, 70, 30], page_layout: :landscape)
        pdf.font_size = 8
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
          ['Auftrag', @work_items[0].label_ancestry], #TODO: Fix this to more robust approach
          ['Periode', @period.to_s],
          ['Verrechenbar', params[:billable].present? ? t("global.#{params[:billable]}") : 'Alle'],
          ['Rapport Stand', Period.current_day.to_s]
        ]

        # Draw customer/order/time info as a table
        pdf.text "Zeitrapport #{Company.name}", size: 18, style: :bold
        pdf.move_down 20 # Space before table

        pdf.table(customer_data, header: false, cell_style: { padding: 4, border_width: 0.3 }, width: pdf.bounds.width * 0.5) do

          cells.borders = %i[bottom top] # Only horizontal lines
          cells.border_color = 'dddddd'

          (0..row_length - 1).each do |index|
            cells[index, 0].font_style = :bold
          end
        end
        pdf.move_down 20
        pdf
      end

      def timestamp_to_daytime(time)
        I18n.l(time, format: :time) if time
      end

      # Builds the table rows as string list according to the passed params
      def table_rows
        # Define table headers
        data = []
        header = %w[Datum Stunden]
        header << 'Von' << 'Bis' if params[:start_stop]
        header << 'Member'
        header << 'Buchungsposition' if params[:show_work_item]
        header << 'Ticket' if params[:show_ticket]
        header << 'Bermerkungen' if params[:description]

        data << header

        # Add table rows
        @worktimes.each do |w|
          row = [w.date_string, format('%.2f', w.hours)]
          row << (timestamp_to_daytime(w.from_start_time) || '') << (timestamp_to_daytime(w.to_end_time) || '') if params[:start_stop]
          row << w.employee.to_s
          row << w.work_item.to_s if params[:show_work_item]
          row << w.ticket if params[:show_ticket]
          row << w.description if params[:description]

          data << row
        end

        total_row = ['Total:', format('%.2f', @worktimes.sum(&:hours))]
        total_row << '' << '' if params[:start_stop]
        total_row << ''
        total_row << '' if params[:show_work_item]
        total_row << '' if params[:show_ticket]
        total_row << '' if params[:description]
        data << total_row
        data
      end

      def build_list(pdf)
        pdf.table(table_rows, header: true, cell_style: { padding: 4, border_width: 0.3 }, width: pdf.bounds.width) do |table|
          table.row(0).font_style = :bold
          table.row(0).background_color = 'f0f0f0'  # Light gray
          table.row(0).text_color = '333333'        # Dark gray

          (1..table.row_length - 1).each do |index|
            table.row(index).background_color = index.even? ? 'f0f0f0' : 'ffffff'
          end

          table.column(1).align = :right # Right-align hours
          if params[:start_stop]
            table.column(2).align = :center
            table.column(3).align = :center
          end

          table.cells.borders = [:bottom] # Only horizontal lines
          table.cells.border_color = 'dddddd' # Light gray borders

          table.row(-1).font_style = :bold
          table.row(-1).borders = [:top]
          table.row(-1).background_color = 'ffffff'

          table.row(-1).column(0).align = :right
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
          pdf.draw_text Company.name, at: [pdf.bounds.left, pdf.bounds.bottom - 38], size: 8
          # pdf.draw_text 'Addresse', at: [pdf.bounds.left, pdf.bounds.bottom - 29], size: 8
          # pdf.draw_text 'Kontaktdaten', at: [pdf.bounds.left, pdf.bounds.bottom - 38], size: 8
        end
        pdf
      end
    end
  end
end
