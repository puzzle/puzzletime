# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Order
  module Services
    class TimeRapportPdfGenerator
      attr_reader :order, :params

      def initialize(data, params = {})
        @order = data[:order]
        @worktimes = data[:worktimes]
        @tickets = data[:tickets]
        @ticket_view = data[:ticket_view]
        @work_items = data[:work_items]
        @employees = data[:employees]
        @employee = data[:employee]
        @period = data[:period]
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
          ['Kunde', @work_items[0].top_item.client.label]
        ]
        customer_data << if @order.present?
                           ['Auftrag', @order.to_s]
                         else
                           ['Auftrag', @work_items.map(&:label_ancestry).join("\n")]
                         end

        customer_data << ['Member', @employee.label] if @employee
        customer_data << ['Periode', @period.to_s]
        customer_data << ['Verrechenbar', params[:billable].present? ? I18n.t("global.#{params[:billable]}") : 'Alle']
        customer_data << ['Rapport Stand', "#{Time.zone.now.strftime('%d.%m.%Y, %H:%M')} Uhr"]

        # Draw customer/order/time info as a table
        pdf.text "Zeitrapport #{Company.name}", size: 18, style: :bold
        pdf.move_down 20

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

      def f_hour(time)
        I18n.l(time, format: :time) if time
      end

      def f_date(time)
        I18n.l(time, format: :long) if time
      end

      # Builds the table rows as string list according to the passed params
      def worktimes_table_rows # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        # Define table headers
        data = []
        header = %w[Datum Stunden]
        header << 'Von' << 'Bis' if params[:start_stop]
        header << 'Member'
        header << 'Buchungsposition' if params[:show_work_item]
        header << 'Ticket' if params[:show_ticket]
        header << 'Bemerkungen' if params[:description]

        data << header

        # Add table rows
        @worktimes.each do |w|
          row = [w.date_string, format('%.2f', w.hours)]
          row << (f_hour(w.from_start_time) || '') << (f_hour(w.to_end_time) || '') if params[:start_stop]
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

      def tickets_table_rows
        # Define table headers
        data = []
        header = %w[Ticket Stunden]
        header << 'Von' << 'Bis' if params[:start_stop]
        header << 'Member'
        header << 'Bemerkungen' if params[:description]

        data << header

        total = 0

        # Add table rows
        @tickets.each do |tckt_key, tckt_val|
          row = [tckt_key, format('%.2f', tckt_val[:sum])]
          row << f_date(tckt_val[:date][0]) << f_date(tckt_val[:date][0]) if params[:start_stop]
          if params[:combine] == 'ticket'
            row << tckt_val[:employees].keys.sort.map { |e| @employees[e] }.join(', ')
          elsif params[:combine] == 'ticket_employee'
            a = []
            tckt_val[:employees].each_pair { |k, v| a << "#{@employees[k]} (#{v[0].round(2)}h)" }
            row << a.sort.join(', ')
          end
          row << tckt_val[:descriptions].join(', ') if params[:description]

          total += tckt_val[:sum]

          data << row
        end

        total_row = ['Total:', format('%.2f', total)]
        total_row << '' << '' if params[:start_stop]
        total_row << ''
        total_row << '' if params[:description]
        data << total_row
        data
      end

      def build_list(pdf)
        data = @ticket_view ? tickets_table_rows : worktimes_table_rows
        pdf.table(data, header: true, cell_style: { padding: 4, border_width: 0.3 }, width: pdf.bounds.width, column_widths: { 0 => 65, 1 => 38 }) do |table|
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
