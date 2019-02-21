# frozen_string_literal: true

#  Copyright (c) 2006-2019, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Expenses::PdfExport
  include ActiveStorage::Downloading

  attr_accessor :pdf
  attr_reader   :expense, :blob, :entries

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
  end

  def build
    validate
    setup_fonts
    expenses.each_with_index do |e, i|
      @expense = e
      pdf.start_new_page unless i.zero?
      add_header
      add_receipt
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
    pdf.column_box([pdf.bounds.left, pdf.bounds.top], columns: 3, width: pdf.bounds.width, height: 100) do
      add_model_data
    end
  end

  def add_model_data
    model_data.each do |k, v|
      add_text attribute(k, v)
    end
  end

  def add_text(text)
    pdf.text text, inline_format: true
  end

  def format_employee(employee)
    "#{employee.firstname} #{employee.lastname}" if employee
  end

  def format_value
    "#{expense.amount} #{Settings.defaults.currency}"
  end

  def format_order
    expense.order&.path_shortnames
  end

  def format_date(date)
    I18n.l(date, format: '%d.%m.%Y') if date
  end

  def model_data # rubocop:disable Metrics/AbcSize
    output = {}
    output[:employee_id]         = format_employee(expense.employee)
    output[:kind]                = expense.kind_value
    output[:order_id]            = format_order if expense.project?
    output[:status]              = expense.status_value
    output[:reviewer_id]         = format_employee(expense.reviewer) if expense.approved?
    output[:reviewed_at]         = format_date(expense.reviewed_at)  if expense.approved?
    output[:reimbursement_month] = expense.reimbursement_month       if expense.approved?
    output[:rejection]           = expense.rejection&.truncate(90)   if expense.rejected?
    output[:id]                  = expense.id
    output[:amount]              = format_value
    output[:payment_date]        = format_date(expense.payment_date)
    output[:description]         = expense.description&.truncate(90) if expense.description
    output[:receipt]             = receipt_text
    output
  end

  def attribute(title, value)
    "<b>#{t(title)}:</b> #{value}"
  end

  def receipt_printable?
    receipt.attached? && (receipt.image? || receipt.previewable?)
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

    @blob = receipt.image? ? receipt.blob : receipt.preview({}).image.blob
    download_blob_to_tempfile do |file|
      pdf.image file.path, position: :center, height: image_height
    end
  end

  def image_height
    pdf.bounds.height - (pdf.bounds.height - pdf.cursor)
  end

  def t(label, **kwargs)
    I18n.t("activerecord.attributes.expense.#{label}", kwargs)
  end

end
