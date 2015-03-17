clients = WorkItem.seed(:shortname, :parent_id,
  { shortname: 'PITC',
    name: 'Puzzle ITC' },

  { shortname: 'SWIS',
    name: 'Swisscom AG' },

  { shortname: 'BLS',
    name: 'BLS AG' }
)

Client.seed(:work_item_id,
  { work_item_id: clients[0].id },

  { work_item_id: clients[1].id },

  { work_item_id: clients[2].id },
)

categories = WorkItem.seed(:shortname, :parent_id,
  { shortname: 'IPR',
    name: 'Interne Projekte',
    parent_id: clients[0].id },

  { shortname: 'EVE',
    name: 'Events',
    parent_id: clients[0].id },

  { shortname: 'FIS',
    name: 'FIS',
    parent_id: clients[2].id }
)

orders = WorkItem.seed(:shortname, :parent_id,
  { shortname: 'PTI',
    name: 'PuzzleTime',
    parent_id: categories[0].id },

  { shortname: 'TTA',
    name: 'Tech Talk',
    parent_id: categories[1].id },

  { shortname: 'WSH',
    name: 'Workshops',
    parent_id: categories[1].id },

  { shortname: 'ENC',
    name: 'enClouder',
    parent_id: clients[1].id },

  { shortname: 'GPA',
    name: 'Grundpacket',
    parent_id: categories[2].id },

  { shortname: 'ERW',
    name: 'Erweiterungen',
    parent_id: categories[2].id },

  { shortname: 'DIS',
    name: 'Driver Info',
    parent_id: clients[2].id },
)

Order.seed(:work_item_id,
  # Puzzletime
  { work_item_id: orders[0].id,
    kind_id: OrderKind.find_by_name('Projekt').id,
    responsible_id: Employee.find_by_shortname('AR').id,
    status_id: OrderStatus.find_by_name('Bearbeitung').id,
    department_id: Department.find_by_name('/dev/two').id,
    order_team_members: %w(BS PZ DI).map {|short| OrderTeamMember.new(employee: Employee.find_by_shortname(short)) }},

  # Tech Talk
  { work_item_id: orders[1].id,
    kind_id: OrderKind.find_by_name('Consulting').id,
    responsible_id: Employee.find_by_shortname('MW').id,
    status_id: OrderStatus.find_by_name('Bearbeitung').id,
    department_id: Department.find_by_name('/dev/one').id  },

  # Workshops
  { work_item_id: orders[2].id,
    kind_id: OrderKind.find_by_name('Consulting').id,
    responsible_id: Employee.find_by_shortname('BS').id,
    status_id: OrderStatus.find_by_name('Bearbeitung').id,
    department_id: Department.find_by_name('/dev/two').id  },

  # Enclouder
  { work_item_id: orders[3].id,
    kind_id: OrderKind.find_by_name('Mandat').id,
    responsible_id: Employee.find_by_shortname('AR').id,
    status_id: OrderStatus.find_by_name('Bearbeitung').id,
    department_id: Department.find_by_name('/dev/two').id,
    order_team_members: %w(PZ BS).map {|short| OrderTeamMember.new(employee: Employee.find_by_shortname(short)) }},

  # FIS Grundpacket
  { work_item_id: orders[4].id,
    kind_id: OrderKind.find_by_name('Mandat').id,
    responsible_id: Employee.find_by_shortname('AR').id,
    status_id: OrderStatus.find_by_name('Abgeschlossen').id,
    department_id: Department.find_by_name('/dev/two').id  },

  # FIS Erweiterungen
  { work_item_id: orders[5].id,
    kind_id: OrderKind.find_by_name('Mandat').id,
    responsible_id: Employee.find_by_shortname('AR').id,
    status_id: OrderStatus.find_by_name('Abschluss').id,
    department_id: Department.find_by_name('/dev/two').id,
    order_team_members: [OrderTeamMember.new(employee: Employee.find_by_shortname('DI'))] },

  # DIS
  { work_item_id: orders[6].id,
    kind_id: OrderKind.find_by_name('Mandat').id,
    responsible_id: Employee.find_by_shortname('BS').id,
    status_id: OrderStatus.find_by_name('Bearbeitung').id,
    department_id: Department.find_by_name('/dev/two').id,
    order_team_members: [OrderTeamMember.new(employee: Employee.find_by_shortname('DI'))] },
)

accounting_posts = WorkItem.seed(:shortname, :parent_id,
  { shortname: 'OPF',
    name: 'Version 1.5',
    parent_id: orders[0].id },

  { shortname: 'ERP',
    name: 'Version ERP',
    parent_id: orders[0].id },

  { shortname: 'E13',
    name: 'Erweiterungen 2013',
    parent_id: orders[3].id },

  { shortname: 'E14',
    name: 'Erweiterungen 2014',
    parent_id: orders[3].id },

  { shortname: 'GP0',
    name: 'Grundpacket 0',
    parent_id: orders[4].id },

  { shortname: 'BAE',
    name: 'Backend',
    parent_id: orders[5].id },

  { shortname: 'FRE',
    name: 'Frontend',
    parent_id: orders[5].id },

  { shortname: 'MID',
    name: 'Middleware',
    parent_id: orders[5].id }
)

AccountingPost.seed(:work_item_id,
  # Puzzletime 1.5
  { work_item_id: accounting_posts[0].id,
    portfolio_item_id: PortfolioItem.find_by_name('Ruby on Rails').id,
    offered_hours: 500,
    billable: false },

  # Puzzletime ERP
  { work_item_id: accounting_posts[1].id,
    portfolio_item_id: PortfolioItem.find_by_name('Ruby on Rails').id,
    offered_hours: 500,
    billable: false },

  # Enclouder 2013
  { work_item_id: accounting_posts[2].id,
    portfolio_item_id: PortfolioItem.find_by_name('Ruby on Rails').id,
    offered_hours: 800,
    offered_rate: 150,
    billable: true,
    closed: true },

  # Enclouder 2014
  { work_item_id: accounting_posts[3].id,
    portfolio_item_id: PortfolioItem.find_by_name('Ruby on Rails').id,
    offered_hours: 600,
    offered_rate: 160,
    billable: true },

  # FIS Grundpacket 0
  { work_item_id: accounting_posts[4].id,
    portfolio_item_id: PortfolioItem.find_by_name('Java EE').id,
    offered_hours: 200,
    offered_rate: 140,
    billable: true,
    closed: true },

  # FIS Backend
  { work_item_id: accounting_posts[5].id,
    portfolio_item_id: PortfolioItem.find_by_name('Java EE').id,
    offered_hours: 2000,
    offered_rate: 140,
    discount_percent: 2,
    billable: true },

  # FIS Frontend
  { work_item_id: accounting_posts[6].id,
    portfolio_item_id: PortfolioItem.find_by_name('Java EE').id,
    offered_hours: 1200,
    offered_rate: 140,
    billable: true },

  # FIS Middleware
  { work_item_id: accounting_posts[7].id,
    portfolio_item_id: PortfolioItem.find_by_name('Java EE').id,
    offered_hours: 200,
    offered_rate: 150,
    discount_fixed: 4000,
    billable: true },

  # TechTalk
  { work_item_id: orders[1].id,
    portfolio_item_id: PortfolioItem.find_by_name('Java EE').id,
    billable: false },

  # Workshops
  { work_item_id: orders[2].id,
    portfolio_item_id: PortfolioItem.find_by_name('Java EE').id,
    billable: false },

  # DIS
  { work_item_id: orders[6].id,
    portfolio_item_id: PortfolioItem.find_by_name('Java EE').id,
    offered_hours: 5000,
    offered_rate: 145,
    billable: true },
)
