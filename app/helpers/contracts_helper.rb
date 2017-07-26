# encoding: utf-8

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


module ContractsHelper
  def format_contract_notes(contract)
    auto_link(simple_format(contract.notes))
  end

  def format_contract_sla(contract)
    auto_link(simple_format(contract.sla))
  end
end
