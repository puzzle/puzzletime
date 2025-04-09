# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class Invoice
  class Report
    class Entry < SimpleDelegator
      attr_reader :invoice

      delegate :reference, :total_amount, :total_hours, :period_from, :period_to, :billing_date, :due_date, :status, to: :invoice

      def initialize(invoice)
        super(invoice)
        @invoice = invoice
      end

      def manual_invoice
        @invoice.manual_invoice?
      end

      def order
        @invoice.order
      end

      def client
        @invoice.order.parent_names
      end

      def responsible
        @invoice.order.responsible
      end

      def department
        @invoice.order.department
      end
    end
  end
end
