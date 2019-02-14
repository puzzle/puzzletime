#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module Invoicing
  # Access the active Invoicing class here
  cattr_accessor :instance

  def self.init
    if Settings.small_invoice.api_token && !Rails.env.test?
      Invoicing.instance = Invoicing::SmallInvoice::Interface.new
      InvoicingSyncJob.schedule if Delayed::Job.table_exists?
    end
  end
end
