# encoding: utf-8

class AttendanceSplit < Splitable

  SUBMIT_BUTTONS = ['Speichern und weiter Aufteilen', WorktimesController::FINISH]

  def page_title
    'Anwesenheit aufteilen'
  end


end
