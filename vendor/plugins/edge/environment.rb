##
## Load the library
##
require 'helpers/calendar'
require 'extensions/boiler_plate'

##
## Inject includes for libraries
##

ActionView::Base.send(:include, ActionView::Helpers::DhtmlCalendarHelper)
