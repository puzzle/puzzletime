class CrmSyncJob < BaseJob

  self.cron_expression = '34 2 * * *'

  def perform
    Crm.instance.sync_all
  end

end