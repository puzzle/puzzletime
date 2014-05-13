class AttendanceSplit < Splitable

  SUBMIT_BUTTONS = ['Speichern und weiter Aufteilen', WorktimeController::FINISH]

  def page_title
    'Anwesenheit aufteilen'
  end


end
