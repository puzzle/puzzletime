module Invoicing
  # Access the active Invoicing class here
  cattr_accessor :instance

  def self.init
    if Settings.small_invoice.api_token
      Invoicing.instance = Invoicing::SmallInvoice::Interface.new
      InvoicingSyncJob.new.schedule if Delayed::Job.table_exists?
    end
  end
end
