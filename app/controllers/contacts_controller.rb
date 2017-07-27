#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


class ContactsController < ManageController
  self.nesting = [Client]

  self.permitted_attrs = [:lastname, :firstname, :function, :email, :phone, :mobile, :crm_key]

  self.search_columns = [:lastname, :firstname, :function, :email]

  def with_crm
    @client = Client.find_by!(work_item_id: params[:client_work_item_id])
    @entries = @client.contacts.list.to_a
    if Crm.instance
      existing = @entries.collect(&:crm_key).compact
      Crm.instance.find_client_contacts(@client).each do |c|
        @entries << @client.contacts.new(c) unless existing.include?(c[:crm_key].to_s)
      end
    end
  end
end
