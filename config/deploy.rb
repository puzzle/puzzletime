set :application, "puzzletime"
set :repository,  ":ext:puzzletime@cvs.ww2.ch:/cvsroot/puzzle"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/home/puzzletime/www/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion
set :scm, :cvs
# set :scm_module, "puzzletime"

role :app, "apollo.ww2.ch"
role :web, "apollo.ww2.ch"
role :db,  "apollo.ww2.ch", :primary => true