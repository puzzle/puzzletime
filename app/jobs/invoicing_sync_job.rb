class InvoicingSyncJob < CronJob

  self.cron_expression = '34 5 * * *'

  def perform
    Invoicing.instance.sync_all
  end

end
