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
