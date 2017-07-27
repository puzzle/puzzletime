#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


namespace :db do
  namespace :dump do
    desc 'Load a db dump from the given FILE'
    task load: ['db:drop', 'db:create'] do
      if ENV['FILE'].blank?
        STDERR.puts 'Usage: FILE=/path/to/dump.sql rake db:dump:load'
        exit 1
      end

      c = ActiveRecord::Base.connection_config
      sh({ 'PGPASSWORD' => c[:password] },
         %W(psql
            -U #{c[:username]}
            -f #{ENV['FILE']}
            -h #{c[:host]}
            #{c[:database]}).join(' '))
      Rake::Task['db:migrate'].invoke
    end
  end

  desc 'Create testusers unless exist'
  task create_testuser: :environment do
    mb1 = Employee.where(shortname: 'MB1').first_or_create!(firstname: 'First',
                                                            lastname: 'Member',
                                                            passwd: Employee.encode('member'),
                                                            email: 'mb1@puzzle.ch', management: false)
    Employment.where(employee_id: mb1.id).first_or_create!(percent: 100, start_date: Date.new(2010, 1, 1))

    mb2 = Employee.where(shortname: 'MB2').first_or_create!(firstname: 'Second',
                                                            lastname: 'Member',
                                                            passwd: Employee.encode('member'),
                                                            email: 'mb2@puzzle.ch',
                                                            management: false)
    Employment.where(employee_id: mb2.id).first_or_create!(percent: 80, start_date: Date.new(2014, 9, 1))
  end
end
