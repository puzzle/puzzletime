# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

require './lib/create_testuser'

namespace :db do # rubocop:disable Metrics/BlockLength
  namespace :dump do
    desc 'Load a db dump from the given FILE'
    task load: ['db:drop', 'db:create'] do
      if ENV['FILE'].blank?
        warn 'Usage: FILE=/path/to/dump.sql rake db:dump:load'
        exit 1
      end

      c = ActiveRecord::Base.connection_config
      sh({ 'PGPASSWORD' => c[:password] },
         %W[psql
            -U #{c[:username]}
            -f #{ENV.fetch('FILE', nil)}
            -h #{c[:host]}
            #{c[:database]}].join(' '))
      Rake::Task['db:migrate'].invoke
    end
  end

  desc 'Drops existing testusers'
  task drop_testusers: :environment do
    Employee.where(shortname: %w[MB1 MB2 MGT]).delete_all
  end

  desc 'Create missing testusers, passwords are random unless provided by env
    MB1=<password>
    MB2=<password2>
    MGT=<password3>
  '
  task create_testusers: :environment do
    CreateTestuser.run(
      shortname: 'MB1',
      employee: {
        firstname: 'First',
        lastname: 'Member',
        password: ENV['MB1'] || Devise.friendly_token(64),
        email: 'mb1@puzzle.ch',
        management: false
      },
      role: {
        name: 'T1 Software Engineer',
        billable: true,
        level: true
      },
      level: {
        name: 'S3'
      },
      employment: {
        percent: 100,
        start_date: Date.new(2010, 1, 1)
      },
      role_employment: {
        employment: @employment,
        employment_role: @role,
        employment_role_level: @level,
        percent: 100
      }
    )

    CreateTestuser.run(
      shortname: 'MB2',
      employee: {
        firstname: 'Second',
        lastname: 'Member',
        password: ENV['MB2'] || Devise.friendly_token(64),
        email: 'mb2@puzzle.ch',
        management: false
      },
      role: {
        name: 'T2 System Engineer',
        billable: true,
        level: true
      },
      level: {
        name: 'S4'
      },
      employment: {
        percent: 80,
        start_date: Date.new(2014, 9, 1)
      },
      role_employment: {
        percent: 80
      }
    )

    CreateTestuser.run(
      shortname: 'MGT',
      employee: {
        firstname: 'Manager',
        lastname: 'Management',
        password: ENV['MGT'] || Devise.friendly_token(64),
        email: 'mgt@puzzle.ch',
        management: true
      },
      role: {
        name: 'T2 System Engineer',
        billable: true,
        level: true
      },
      level: {
        name: 'S4'
      },
      employment: {
        percent: 80,
        start_date: Date.new(2014, 9, 1)
      },
      role_employment: {
        percent: 80
      }
    )
  end
end
