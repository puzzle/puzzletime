# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

module Plannings
  class CompanyNotesController < ApplicationController
    before_action :set_employee

    # Rendered into the modal dialog; the modal JS requests these as `.js`.
    def show
      authorize!(:read, Planning)
      render :show, formats: :html, layout: false
    end

    def edit
      authorize!(:update_planning_note, @employee)
      render :edit, formats: :html, layout: false
    end

    def update
      authorize!(:update_planning_note, @employee)

      if @employee.update(planning_note_params)
        # Response shape expected by processCreatedEntry (app/assets/javascripts/modal_create.js.coffee)
        render plain: "'#{helpers.escape_javascript({ content: note_link_html }.to_json)}'"
      else
        render :edit, formats: :html, layout: false, status: :unprocessable_content
      end
    end

    private

    def set_employee
      @employee = Employee.find(params[:id])
    end

    def planning_note_params
      params.require(:employee).permit(:planning_note)
    end

    def note_link_html
      render_to_string(partial: 'plannings/company_notes/link',
                       formats: :html,
                       locals: { employee: @employee })
    end
  end
end
