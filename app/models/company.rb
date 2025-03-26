# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

# Helper class to provide information for the organisation represented by PuzzleTime.
class Company
  class << self
    delegate :name, to: :client

    def client
      RequestStore.store['company_client'] ||= Client.find(Settings.clients.company_id)
    end

    def logo_path
      file?('company_logo.png') ? 'company_logo.png' : nil
    end

    delegate :work_item_id, to: :client

    private

    def file?(path)
      Rails.application.assets.find_asset(path) != nil
    end
  end
end
