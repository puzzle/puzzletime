employees = Employee.seed(:shortname,
  { firstname: 'Mark',
    lastname: 'Waber',
    shortname: 'MW',
    passwd: '86f7e437faa5a7fce15d1ddcb9eaeaea377667b8', # a
    email: 'waber@puzzle.ch',
    management: true },

  { firstname: 'Andreas',
    lastname: 'Rava',
    shortname: 'AR',
    passwd: '86f7e437faa5a7fce15d1ddcb9eaeaea377667b8', # a
    email: 'rava@puzzle.ch',
    management: true },

  { firstname: 'Pascal',
    lastname: 'Zumkehr',
    shortname: 'PZ',
    passwd: '86f7e437faa5a7fce15d1ddcb9eaeaea377667b8', # a
    email: 'zumkehr@puzzle.ch',
    management: false },

  { firstname: 'Bruno',
    lastname: 'Santschi',
    shortname: 'BS',
    passwd: '86f7e437faa5a7fce15d1ddcb9eaeaea377667b8', # a
    email: 'santschi@puzzle.ch',
    management: false },

  { firstname: 'Daniel',
    lastname: 'Illi',
    shortname: 'DI',
    passwd: '86f7e437faa5a7fce15d1ddcb9eaeaea377667b8', # a
    email: 'illi@puzzle.ch',
    management: true }
)

Employment.seed(:employee_id, :start_date,
  { employee_id: employees[0].id,
    percent: 100,
    start_date: Date.new(2000, 1, 1) },

  { employee_id: employees[1].id,
    percent: 90,
    start_date: Date.new(2009, 5, 1) },

  { employee_id: employees[2].id,
    percent: 60,
    start_date: Date.new(2005, 12, 1),
    end_date: Date.new(2012, 4, 30) },

  { employee_id: employees[2].id,
    percent: 80,
    start_date: Date.new(2012, 5, 1) },

  { employee_id: employees[3].id,
    percent: 100,
    start_date: Date.new(2008, 3, 1) },

  { employee_id: employees[4].id,
    percent: 60,
    start_date: Date.new(2007, 9, 1) },
)
