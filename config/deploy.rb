set :application, "puzzletime"
set :repository,  ":ext:puzzletime@cvs.ww2.ch:/cvsroot/puzzle"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/home/puzzletime/www"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion
set :scm, :cvs
set :scm_module, "puzzletime"


set :user, "puzzletime"
set :runner, "puzzletime"

role :app, "apollo.ww2.ch"
role :web, "apollo.ww2.ch"
role :db,  "apollo.ww2.ch", :primary => true


task :restart_web_server, :roles => :web do
  # restart your web server here
  sudo "/etc/init.d/lighttpd restart"
end

task :chown_files, :roles => :app do
  sudo "chown -R #{user}:lighttpd #{release_path}"
end

deploy.task :start do
   #nothing
end

deploy.task :restart do
  #nothing
end

after "deploy:update_code", :chown_file
after "deploy:start", :restart_web_server
after "deploy:restart", :restart_web_server





