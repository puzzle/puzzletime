#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


employees = Employee.seed(:shortname,
  { firstname: 'Mark',
    lastname: 'Waber',
    shortname: 'MW',
    passwd: Employee.encode('a'),
    email: 'waber@puzzle.ch',
    management: true },

  { firstname: 'Andreas',
    lastname: 'Rava',
    shortname: 'AR',
    passwd: Employee.encode('a'),
    email: 'rava@puzzle.ch',
    management: true },

  { firstname: 'Pascal',
    lastname: 'Zumkehr',
    shortname: 'PZ',
    passwd: Employee.encode('a'),
    email: 'zumkehr@puzzle.ch',
    management: false },

  { firstname: 'Bruno',
    lastname: 'Santschi',
    shortname: 'BS',
    passwd: Employee.encode('a'),
    email: 'santschi@puzzle.ch',
    management: false },

  { firstname: 'Daniel',
    lastname: 'Illi',
    shortname: 'DI',
    passwd: Employee.encode('a'),
    email: 'illi@puzzle.ch',
    management: true },

  { firstname: 'Päscu',
    lastname: 'Simon',
    shortname: 'PSI',
    passwd: Employee.encode('a'),
    email: 'simon@puzzle.ch',
    management: false },

  { firstname: 'Thomas',
    lastname: 'Burkhalter',
    shortname: 'TBU',
    passwd: Employee.encode('a'),
    email: 'burkhalter@puzzle.ch',
    management: false }
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

  { employee_id: employees[6].id,
    percent: 100,
    start_date: Date.new(2018, 5, 1) },
)
