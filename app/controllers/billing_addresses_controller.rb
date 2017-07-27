#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class BillingAddressesController < ManageController
  self.nesting = [Client]

  self.permitted_attrs = [:contact_id, :supplement, :street, :zip_code, :town, :country]

  before_render_form :set_contacts

  private

  def set_contacts
    @contacts = parent.contacts.list
  end
end
