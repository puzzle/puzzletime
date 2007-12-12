require 'dispatcher'
# The special :request benchmark. This tries to encompass everything that runs
# to handle a request.
BenchmarkForRails.watch(:request, ::Dispatcher, :dispatch)

# Processing the action itself (calling the controller method)
# This is what Rails' default benchmarks claim is the response time.
BenchmarkForRails.watch("processing action", ActionController::Base, :perform_action)

# Tries to give some perspective on how much time is tied up in reloading the
# application for development mode.
if RAILS_ENV == 'development'
  BenchmarkForRails.watch("development mode", Dispatcher, :prepare_application)
end

# Session management is normally small, although sometimes it's still a
# significant percentage.
BenchmarkForRails.watch("session management", CGI::Session, :initialize)
BenchmarkForRails.watch("session management", ActionController::Base, :close_session)

# Controller filters
BenchmarkForRails.watch("before filters", ActionController::Filters::InstanceMethods, :run_before_filters)
BenchmarkForRails.watch("after filters", ActionController::Filters::InstanceMethods, :run_after_filters)

# The real cost of database access should include query construction.
# Hence why we try and watch the core finder. More watches might be added
# to this group to form a more complete picture of database access. The
# question is simply which methods bypass find().
BenchmarkForRails.watch("activerecord find", ActiveRecord::Base, :find, false)

# And yes, it's still important to know how much time is spent rendering.
BenchmarkForRails.watch("rendering", ActionController::Base, :render)

# Should be included after the BenchmarkForRails.watch(:request, ...),
# since it hooks into the same method.
require 'reporting'