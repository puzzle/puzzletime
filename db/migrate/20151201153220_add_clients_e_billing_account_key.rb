# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class AddClientsEBillingAccountKey < ActiveRecord::Migration[5.1]
  def change
    add_column :clients, :e_bill_account_key, :string
  end
end
