# Helper class to provide information for the organisation represented by PuzzleTime.
class Company
  class << self

    def name
      client.name
    end

    def client
      RequestStore.store['company_client'] ||= Client.find(Settings.clients.company_id)
    end

    def work_item_id
      client.work_item_id
    end

  end
end