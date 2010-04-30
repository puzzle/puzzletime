# ############################## #
# Global settings for puzzleTime #
# ############################## #

# Masterdata for time calculations.
# DO NOT CHANGE THAT WITHOUT A GOOD REASON !
MUST_HOURS_PER_DAY      = 8.0
VACATION_DAYS_PER_YEAR  = 25.0

# Significant IDs
# THIS SHOULD BE SYNCED WITH THE DATABASE !
VACATION_ID             = 1
DEFAULT_PROJECT_ID      = 8   # Puzzle Allgemein

# Array of holidays with a fixed date. [day, month]
REGULAR_HOLIDAYS        = [[1,1],[2,1],[1,8],[25,12],[26,12]]
  
# Email settings for error messages
SYSTEM_EMAIL            = %{"PuzzleTime" <monitor-sender@worldweb2000.com>}
EXCEPTION_RECIPIENTS    = ["santschi@puzzle.ch"]

# LDAP configuration
LDAP_HOST               = 'proximai.ww2.ch'
LDAP_PORT               = 636
LDAP_USER_DN            = 'ou=puzzle,ou=users,dc=puzzle,dc=itc'
LDAP_EXTERNAL_DN        = 'ou=extern,ou=users,dc=puzzle,dc=itc'
LDAP_GROUP              = 'cn=puzzletime,ou=groups,dc=puzzle,dc=itc'

# Applications Customization Settings
NO_OF_OVERVIEW_ROWS     = 20      # rows for listing projects, employees, ...
NO_OF_DETAIL_ROWS       = 20      # rows for detail time entries
PAGINATION_WINDOW_SIZE  = 10      

DATE_FORMAT             = '%d.%m.%Y'
LONG_DATE_FORMAT        = '%a, %d.%m.%Y'
TIME_FORMAT             = '%H:%M'
WEEK_FORMAT             = '%Y %W'

# Default values
DEFAULT_REPORT_TYPE     = HoursDayType::INSTANCE
DEFAULT_START_HOUR      = 8

 # from/to day of month to display completion notification
DISPLAY_COMPLETION = [26, 2]