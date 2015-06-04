module Crm
  # Access the active CRM class here
  cattr_accessor :instance

  def self.init
    if Settings.highrise.api_token
      Crm.instance = Crm::Highrise.new
      CrmSyncJob.new.schedule if Delayed::Job.table_exists?
    end
  end
end
