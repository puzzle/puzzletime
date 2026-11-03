# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Expenses
  # Attaches an uploaded receipt to an expense: images are resized and converted to jpg, PDFs keep
  # their page count. Shared by ExpensesController and the API.
  class ReceiptAttacher
    require 'ruby-vips'

    def initialize(expense)
      @expense = expense
    end

    # `file` is a File/Tempfile. Does nothing (returns nil) when the content type is neither PDF nor image.
    def attach(file, filename:, content_type:)
      case content_type
      when 'application/pdf' then attach_pdf(file, filename)
      when /image/ then attach_image(file, filename)
      end
    end

    private

    def attach_image(file, filename)
      resized = ::ImageProcessing::Vips
                .source(file)
                .resize_to_limit(Settings.expenses.receipt.max_pixel, Settings.expenses.receipt.max_pixel)
                .saver(quality: Settings.expenses.receipt.quality)
                .convert('jpg')
                .loader(page: 0)
                .call

      target_filename = "#{File.basename(filename.to_s, '.*')}.jpg"

      @expense.receipt.attach(io: File.open(resized), filename: target_filename, content_type: 'image/jpeg')
    end

    def attach_pdf(file, filename)
      target_filename = "#{File.basename(filename.to_s, '.*')}.pdf"
      page_count = pdf_pages_amount(file.path)

      @expense.receipt.attach(io: File.open(file), filename: target_filename, content_type: 'application/pdf',
                              metadata: { page_count: })
    end

    def pdf_pages_amount(filepath_pdf)
      first_page = ::Vips::Image.new_from_file(filepath_pdf, page: 0, n: 1)
      first_page.get('n-pages')
    end
  end
end
