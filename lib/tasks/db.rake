namespace :db do
  namespace :dump do
    desc 'Load a db dump from the given FILE'
    task :load => ['db:drop', 'db:create'] do
      c = ActiveRecord::Base.connection_config
      sh({'PGPASSWORD' => c[:password]},
         %W(psql
            -U #{c[:username]}
            -f #{ENV['FILE']}
            -h #{c[:host]}
            #{c[:database]}).join(' '))
      Rake::Task['db:migrate'].invoke
    end
  end
end