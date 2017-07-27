#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


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
