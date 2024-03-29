# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

employees = Employee.seed(
  :shortname,
  { firstname: 'Mark',
    lastname: 'Waber',
    shortname: 'MW',
    password: 'a',
    email: 'waber@puzzle.ch',
    management: true },
  { firstname: 'Andreas',
    lastname: 'Rava',
    shortname: 'AR',
    password: 'a',
    email: 'rava@puzzle.ch',
    management: true },
  { firstname: 'Pascal',
    lastname: 'Zumkehr',
    shortname: 'PZ',
    password: 'a',
    email: 'zumkehr@puzzle.ch',
    management: false },
  { firstname: 'Bruno',
    lastname: 'Santschi',
    shortname: 'BS',
    password: 'a',
    email: 'santschi@puzzle.ch',
    management: false },
  { firstname: 'Daniel',
    lastname: 'Illi',
    shortname: 'DI',
    password: 'a',
    email: 'illi@puzzle.ch',
    management: true },
  { firstname: 'Päscu',
    lastname: 'Simon',
    shortname: 'PSI',
    password: 'a',
    email: 'simon@puzzle.ch',
    management: false },
  { firstname: 'Thomas',
    lastname: 'Burkhalter',
    shortname: 'TBU',
    password: 'a',
    email: 'burkhalter@puzzle.ch',
    management: false },
  { firstname: 'Andreas',
    lastname: 'Zuber',
    shortname: 'AZ',
    password: 'a',
    email: 'zuber@puzzle.ch',
    management: false }
)

employments = Employment.seed(
  :employee_id,
  :start_date,
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
  { employee_id: employees[7].id,
    percent: 100,
    start_date: Date.new(2007, 2, 1) }
)

categories = EmploymentRoleCategory.seed(
  :id,
  { name: 'Management' },
  { name: 'Unterstützend' },
  { name: 'Techboard' },
  { name: 'Berufsbildner' },
  { name: 'Lernende' },
  { name: 'Andere' }
)

roles = EmploymentRole.seed(
  :id,
  { name: 'Software Engineer', billable: true, level: true, employment_role_category_id: nil },
  { name: 'Berufsbildner', billable: false, level: false, employment_role_category_id: categories[3].id },
  { name: 'Mitglied Technical Board', billable: false, level: false, employment_role_category_id: categories[2].id },
  { name: 'Praktikant', billable: false, level: false, employment_role_category_id: categories[4].id },
  { name: 'Qualitätsleiter', billable: false, level: false, employment_role_category_id: categories[5].id },
  { name: 'Lernende', billable: false, level: false, employment_role_category_id: categories[4].id }
)

EmploymentRolesEmployment.seed(
  :employment_id,
  { employment_id: employments[0].id, employment_role_id: roles[0].id, employment_role_level_id: 5, percent: 100 },
  { employment_id: employments[1].id, employment_role_id: roles[1].id, employment_role_level_id: 4, percent: 90 },
  { employment_id: employments[2].id, employment_role_id: roles[2].id, employment_role_level_id: 3, percent: 80 },
  { employment_id: employments[3].id, employment_role_id: roles[3].id, employment_role_level_id: 2, percent: 70 },
  { employment_id: employments[4].id, employment_role_id: roles[4].id, employment_role_level_id: 1, percent: 60 },
  { employment_id: employments[5].id, employment_role_id: roles[5].id, employment_role_level_id: 5, percent: 50 },
  { employment_id: employments[6].id, employment_role_id: roles[0].id, employment_role_level_id: 4, percent: 40 },
  { employment_id: employments[7].id, employment_role_id: roles[1].id, employment_role_level_id: 3, percent: 30 }
)
