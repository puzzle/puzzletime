# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

department = ->(shortname) { Department.find_by!(shortname: shortname).id }

employees = Employee.seed(
  :shortname,
  { firstname: 'Mark',
    lastname: 'Waber',
    shortname: 'MW',
    password: 'a',
    email: 'waber@puzzle.ch',
    management: true,
    department_id: department.call('UX') },
  { firstname: 'Andreas',
    lastname: 'Rava',
    shortname: 'AR',
    password: 'a',
    email: 'rava@puzzle.ch',
    management: true,
    department_id: department.call('UX') },
  { firstname: 'Pascal',
    lastname: 'Zumkehr',
    shortname: 'PZ',
    password: 'a',
    email: 'zumkehr@puzzle.ch',
    management: false,
    department_id: department.call('D1'),
    planning_note: 'Kurzfristig 20% Enclouder-Unterstützung, Rest PuzzleTime.' },
  { firstname: 'Bruno',
    lastname: 'Santschi',
    shortname: 'BS',
    password: 'a',
    email: 'santschi@puzzle.ch',
    management: false,
    department_id: department.call('D2'),
    planning_note: <<~MD },
      # Planung Bruno Santschi

      **Wichtig:** Ab Januar wechselt Bruno teilweise auf das *Driver Info* Projekt.

      ## Ziele fürs Quartal
      - Stabilisierung der Schnittstellen zu den Fachbereichen
      - Einarbeitung der neuen Entwickler im Team
      - Dokumentation im [Projekt-Wiki](https://wiki.puzzle.ch/planung)

      ## Offene Punkte
      - Abstimmung der Ferienplanung mit AR
      - Kapazität im Dezember überprüfen
      - Entscheid über Weiterbildung im Frühling
      - Review der Testabdeckung der Migration

      Bitte Änderungen jeweils mit der Teamleitung besprechen.
    MD
  { firstname: 'Daniel',
    lastname: 'Illi',
    shortname: 'DI',
    password: 'a',
    email: 'illi@puzzle.ch',
    management: true,
    department_id: department.call('SY') },
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
    management: false,
    department_id: department.call('D1') },
  { firstname: 'Andreas',
    lastname: 'Zuber',
    shortname: 'AZ',
    password: 'a',
    email: 'zuber@puzzle.ch',
    management: false,
    department_id: department.call('D2') },
  { firstname: 'Anna ',
    lastname: 'Mund',
    shortname: 'AM',
    password: 'a',
    email: 'mund@puzzle.ch',
    management: false,
    department_id: department.call('D2') }
)

# member coaches reference the management employees seeded above
Employee.seed(
  :shortname,
  { shortname: 'PZ', member_coach_id: employees[0].id },
  { shortname: 'TBU', member_coach_id: employees[0].id },
  { shortname: 'DI', member_coach_id: employees[0].id },
  { shortname: 'BS', member_coach_id: employees[1].id },
  { shortname: 'AZ', member_coach_id: employees[1].id },
  { shortname: 'AM', member_coach_id: employees[1].id }
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
    start_date: Date.new(2007, 2, 1) },
  { employee_id: employees[8].id,
    percent: 60,
    start_date: Date.new(2019, 11, 1) }
)

categories = EmploymentRoleCategory.seed(
  :name,
  { name: 'Management' },
  { name: 'Unterstützend' },
  { name: 'Techboard' },
  { name: 'Berufsbildner' },
  { name: 'Lernende' },
  { name: 'Andere' }
)

roles = EmploymentRole.seed(
  :name,
  { name: 'Software Engineer', billable: true, level: true, employment_role_category_id: nil },
  { name: 'Berufsbildner', billable: false, level: false, employment_role_category_id: categories[3].id },
  { name: 'Mitglied Technical Board', billable: false, level: false, employment_role_category_id: categories[2].id },
  { name: 'Praktikant', billable: false, level: false, employment_role_category_id: categories[4].id },
  { name: 'Qualitätsleiter', billable: false, level: false, employment_role_category_id: categories[5].id },
  { name: 'Lernende', billable: false, level: false, employment_role_category_id: categories[4].id }
)

# only roles with level: true have a level (see EmploymentRolesEmployment#valid_level)
levels = EmploymentRoleLevel.seed(
  :name,
  { name: 'S1' },
  { name: 'S2' },
  { name: 'S3' },
  { name: 'S4' },
  { name: 'S5' }
)

EmploymentRolesEmployment.seed(
  :employment_id,
  { employment_id: employments[0].id, employment_role_id: roles[0].id, employment_role_level_id: levels[4].id, percent: 100 },
  { employment_id: employments[1].id, employment_role_id: roles[1].id, employment_role_level_id: nil, percent: 90 },
  { employment_id: employments[2].id, employment_role_id: roles[2].id, employment_role_level_id: nil, percent: 80 },
  { employment_id: employments[3].id, employment_role_id: roles[3].id, employment_role_level_id: nil, percent: 70 },
  { employment_id: employments[4].id, employment_role_id: roles[4].id, employment_role_level_id: nil, percent: 60 },
  { employment_id: employments[5].id, employment_role_id: roles[5].id, employment_role_level_id: nil, percent: 50 },
  { employment_id: employments[6].id, employment_role_id: roles[0].id, employment_role_level_id: levels[3].id, percent: 40 },
  { employment_id: employments[7].id, employment_role_id: roles[1].id, employment_role_level_id: nil, percent: 30 },
  { employment_id: employments[8].id, employment_role_id: roles[0].id, employment_role_level_id: levels[3].id, percent: 60 }
)
