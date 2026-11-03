# frozen_string_literal: true

#  Copyright (c) 2006-2026, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Api
  module V2
    # CRUD of ExpenseResource plus the two operations that are not plain attribute writes: the receipt (upload with
    # server side image processing, download) and the management review (ExpensesReviewsController). Operation
    # bodies are JSON:API documents: `{ data: { type: 'expenses', attributes: { ... } } }`.
    class ExpensesController < ResourceController
      RECEIPT_MAX_BYTES = 10.megabytes
      RECEIPT_TYPES = %w[image/png image/jpeg image/gif image/webp application/pdf].freeze
      REVIEW_STATUSES = %w[approved rejected deferred].freeze

      # Raised for a receipt that cannot be stored; rendered as a 422 on the `receipt` attribute.
      class ReceiptError < StandardError; end

      # Attach or replace the receipt: attributes `filename` and `data_base64`; images are resized, the file type is
      # detected from the content.
      def update_receipt
        expense = find_expense
        authorize!(:update, expense)
        ExpenseResource.assert_not_approved(expense, current_user)
        ExpenseResource.resubmit_rejected(expense, current_user)
        attach_receipt(expense, operation_attributes)
        save_and_render(expense)
      rescue ReceiptError => e
        expense.errors.add(:receipt, e.message)
        render_validation_errors(expense)
      end

      # Receipt metadata and content, 404 when none is attached.
      def show_receipt
        expense = find_expense
        authorize!(:show, expense)
        receipt = expense.receipt
        return render_error(404, 'Not found') unless receipt.attached?

        render json: { data: { type: 'receipts', id: expense.id.to_s, attributes: receipt_attributes(receipt) } },
               content_type: Mime[:jsonapi]
      end

      # Management decides on an expense: attributes `status` (approved, rejected, deferred), `reimbursement_date`
      # (ignored when rejecting) and `reason`; reviewer and review time are the current user and now.
      def review
        authorize!(:manage, Expense.new)
        expense = find_expense
        attributes = operation_attributes.slice(:status, :reimbursement_date, :reason)
        return render_error(400, "status must be one of #{REVIEW_STATUSES.join(', ')}") \
          unless REVIEW_STATUSES.include?(attributes[:status])
        return render_already_reviewed(expense) unless expense.pending? || expense.deferred?

        attributes.delete(:reimbursement_date) if attributes[:status] == 'rejected'
        expense.assign_attributes(attributes.merge(reviewer: current_user, reviewed_at: Time.zone.now))
        save_and_render(expense)
      end

      private

      # Not `ExpenseResource.find`: Graphiti refuses to serve a resource from an endpoint it is not registered for.
      def find_expense
        ExpenseResource.new.base_scope.find(params[:id])
      end

      def operation_attributes
        params.fetch(:data, {}).fetch(:attributes, {}).permit(:status, :reimbursement_date, :reason, :filename, :data_base64).to_h
      end

      def save_and_render(expense)
        if expense.save
          render jsonapi: ExpenseResource.wrap(expense)
        else
          render_validation_errors(expense)
        end
      end

      def render_validation_errors(expense)
        render json: { errors: Graphiti::ErrorSerializers::Validation.new(expense).errors },
               status: :unprocessable_content, content_type: Mime[:jsonapi]
      end

      def render_already_reviewed(expense)
        expense.errors.add(:status, "#{expense} wurde bereits bearbeitet")
        render_validation_errors(expense)
      end

      def receipt_attributes(receipt)
        { filename: receipt.filename.to_s, content_type: receipt.content_type, byte_size: receipt.byte_size,
          page_count: receipt.metadata[:page_count], data_base64: [receipt.download].pack('m0') }
      end

      def attach_receipt(expense, attributes)
        filename = attributes[:filename]
        raise ReceiptError, 'filename and data_base64 are required' if filename.blank? || attributes[:data_base64].blank?

        data = decode_receipt(attributes[:data_base64])
        type = Marcel::MimeType.for(StringIO.new(data))
        raise ReceiptError, "Unsupported file type #{type}" unless RECEIPT_TYPES.include?(type)

        Tempfile.create(['receipt', File.extname(filename)], binmode: true) do |file|
          file.write(data)
          file.flush
          Expenses::ReceiptAttacher.new(expense).attach(file, filename:, content_type: type)
        end
      rescue Vips::Error
        raise ReceiptError, 'File could not be processed'
      end

      def decode_receipt(encoded)
        raise ReceiptError, 'Receipt is too large' if encoded.bytesize > (RECEIPT_MAX_BYTES * 4 / 3) + 4

        data = encoded.unpack1('m0')
        raise ReceiptError, 'Receipt is too large' if data.bytesize > RECEIPT_MAX_BYTES

        data
      rescue ArgumentError
        raise ReceiptError, 'Receipt is not valid base64'
      end
    end
  end
end
