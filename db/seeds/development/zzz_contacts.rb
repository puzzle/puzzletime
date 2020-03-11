#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

Contact.seed(:client_id, :lastname,
  { client_id: WorkItem.where(parent_id: nil, name: 'Swisscom AG').first!.id,
    lastname: 'von Gunten',
    firstname: 'Thomas',
    function: 'Lead Architect' },
  { client_id: WorkItem.where(parent_id: nil, name: 'BLS AG').first!.id,
    lastname: 'Meier',
    firstname: 'Hans',
    function: 'Einkäufer' },
  { client_id: WorkItem.where(parent_id: nil, name: 'BLS AG').first!.id,
    lastname: 'Freiburghaus',
    firstname: 'Franz',
    function: 'PL' }
)
