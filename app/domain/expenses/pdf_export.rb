# frozen_string_literal: true

#  Copyright (c) 2006-2019, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Expenses
  class PdfExport
    require 'mini_magick'

    attr_accessor :pdf
    attr_reader   :expense, :entries

    FILENAME = 'tmp/expenses.pdf'

    def initialize(entries)
      @pdf     = Prawn::Document.new(page_size: 'A4')
      @entries = entries
    end

    def expenses
      @expenses ||=
        Expense
        .includes(:employee, :reviewer, :reviewer)
        .includes(order: :work_item, receipt_attachment: [{ blob: [{ preview_image_attachment: :blob }] }])
        .where(id: entries)
        .order('employees.lastname')
        .order(:payment_date)
    end

    def build
      validate
      setup_fonts
      expenses.each_with_index do |e, i|
        @expense = e
        pdf.start_new_page unless i.zero?
        add_header
        add_receipt
        reset_model_data
      end
      pdf.number_pages('Seite <page>/<total>', at: [pdf.bounds.right - 60, pdf.bounds.bottom + 5])
    end

    def generate
      build
      pdf.render_file FILENAME
      FILENAME
    end

    private

    def validate
      raise ArgumentError, 'There are no approved expenses.' if expenses.blank?

      true
    end

    def setup_fonts
      pdf.font_families.update(
        'Roboto' => {
          normal: 'app/assets/fonts/Roboto-Regular.ttf',
          italic: 'app/assets/fonts/Roboto-Italic.ttf',
          bold: 'app/assets/fonts/Roboto-Bold.ttf',
          bold_italic: 'app/assets/fonts/Roboto-BoldItalic.ttf'

        }
      )
      pdf.font('Roboto')
    end

    def add_header
      # pdf.column_box([pdf.bounds.left, pdf.bounds.top], columns: 3, width: pdf.bounds.width, height: 100) do
      #   add_model_data
      # end
      pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], width: pdf.bounds.width, height: 150) do
        pdf.define_grid(columns: 2, rows: 1)

        column1 = [:employee_id, :kind, :order_id, :status, nil, nil, { name: :amount, size: 15 }]
        column2 = %i[id reviewer_id reviewed_at reason reimbursement_month payment_date description receipt]

        pdf.grid(0, 0).bounding_box do
          add_model_data(column1)
        end

        pdf.grid(0, 1).bounding_box do
          add_model_data(column2)
        end
      end
    end

    def add_model_data(items)
      items.each do |item|
        add_text ' ' unless item
        add_single_model_data item if item.is_a? Symbol
        add_single_model_data item[:name], size: item[:size] if item.is_a? Hash
      end
    end

    def add_single_model_data(key, **)
      add_text(attribute(key, model_data[key]), **)
    end

    def add_text(text, **options)
      options[:inline_format] = true
      pdf.text text, options
    end

    def format_employee(employee)
      "#{employee.firstname} #{employee.lastname}" if employee
    end

    def format_value
      format(
        '%<amount>0.02f %<currency>s',
        amount: expense.amount,
        currency: Settings.defaults.currency
      )
    end

    def format_order
      expense.order&.path_shortnames
    end

    def format_date(date)
      I18n.l(date, format: '%d.%m.%Y') if date
    end

    def model_data
      @model_data ||=
        begin
          output = {}
          output[:employee_id]         = format_employee(expense.employee)
          output[:status]              = expense.status_value
          output[:kind]                = expense.kind_value
          output[:order_id]            = format_order                      if expense.project?
          output[:reviewer_id]         = format_employee(expense.reviewer) if expense.approved? || expense.rejected?
          output[:reviewed_at]         = format_date(expense.reviewed_at)  if expense.approved? || expense.rejected?
          output[:reimbursement_month] = expense.reimbursement_month       if expense.approved?
          output[:reason]              = expense.reason&.truncate(90)      if expense.approved? || expense.rejected?
          output[:id]                  = expense.id
          output[:amount]              = format_value
          output[:payment_date]        = format_date(expense.payment_date)
          output[:description]         = expense.description&.truncate(90) if expense.description
          output[:receipt]             = receipt_text
          output
        end
    end

    def reset_model_data
      @model_data = nil
    end

    def attribute(title, value)
      "<b>#{t(title)}:</b> #{value}"
    end

    def receipt_printable?
      receipt.attached? && receipt.image? # Currently, previewables will not be handled
    end

    def receipt
      expense.receipt
    end

    def receipt_text
      return receipt.filename if receipt_printable?
      return 'Dieser Beleg kann nicht gedruckt werden.' if receipt.attached?

      'Es wurde kein Beleg beigelegt.'
    end

    def add_receipt
      return unless receipt_printable?

      blob.open do |file|
        # Vips auto rotates by default
        image = ::Vips::Image.new_from_file(file.path)
        rotated = ImageProcessing::Vips.source(image)
        rotated.write_to_file(file.path)
        pdf.image file.path, position: :center, fit: [image_width, image_height]
      end
    rescue StandardError => e
      add_text "Error while adding picture for expense #{@expense.id}"
      add_text "Message: #{e.message}"

      Rails.logger.info "Error while adding picture for expense #{@expense.id}"
      Rails.logger.info "Message: #{e.message}"
      Rails.logger.info "Backtrace: #{e.backtrace.inspect}"
    end

    def blob
      receipt.blob
    end

    def image_width
      pdf.bounds.width
    end

    def image_height
      pdf.bounds.height - (pdf.bounds.height - pdf.cursor)
    end

    def t(label, **)
      I18n.t("activerecord.attributes.expense.#{label}", **)
    end
  end
end
