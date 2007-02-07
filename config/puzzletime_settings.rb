# ############################## #
# Global settings for puzzleTime #
# ############################## #

# Masterdata for time calculations.
# DO NOT CHANGE THAT WITHOUT A GOOD REASON !
MUST_HOURS_PER_DAY      = 8
VACATION_DAYS_PER_YEAR  = 20

# Significant IDs
# THIS SHOULD BE SYNCED WITH THE DATABASE !
VACATION_ID             = 1
DEFAULT_PROJECT_ID      = 8

# Array of holidays with a fixed date. [day, month]
REGULAR_HOLIDAYS        = [[1,1],[2,1],[1,8],[25,12],[26,12]]

# Applications Customization Settings
NO_OF_OVERVIEW_ROWS     = 15      # rows for listing projects, employees, ...
NO_OF_DETAIL_ROWS       = 20      # rows for detail time entries

DATE_FORMAT             = '%d.%m.%Y'
LONG_DATE_FORMAT        = '%a, %d.%m.%Y'

SYSTEM_EMAIL            = %{"PuzzleTime" <puzzletime@puzzle.ch>}
EXCEPTION_RECIPIENTS    = ["zumkehr@puzzle.ch"]

# Default values
DEFAULT_REPORT_TYPE     = ReportType::HOURS_DAY
DEFAULT_START_HOUR      = 8
