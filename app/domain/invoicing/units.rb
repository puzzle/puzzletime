# frozen_string_literal: true

module Invoicing
  class Units
    OPTIONS = {
      'Pauschale' => 13,
      'Stunde' => 1,
      'Tag' => 2,
      'Monat' => 3,
      'Quartal' => 4,
      'Semester' => 5,
      'Jahr' => 6,
      '-' => 14
    }.freeze
  end
end
