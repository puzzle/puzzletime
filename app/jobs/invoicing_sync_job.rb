class InvoicingSyncJob < CronJob

  self.cron_expression = '34 3 * * *'

  def perform
    Invoicing.instance.sync_all
  end

end
