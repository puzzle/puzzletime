# Load the Rails application.
require_relative 'application'

#FIXME: ignoring deprecation warnings for now.
::ActiveSupport::Deprecation.silenced = true if Rails.env.test?

# Initialize the Rails application.
Rails.application.initialize!
