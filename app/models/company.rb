# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


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
