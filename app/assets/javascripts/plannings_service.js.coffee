#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}
app.plannings ||= {}

app.plannings.service = new class
  updateSelected: (url, planning) ->
    planning.utf8 = undefined
    token = planning.authenticity_token
    planning.authenticity_token = undefined

    @update(url,
      planning: planning
      items: app.plannings.selectable.getSelectedDays()
      authenticity_token: token
    ).fail((res) -> console.log('update error', res.status, res.statusText))

  update: (url, data) ->
    $.ajax({
      type: 'PATCH',
      url: url,
      data: @_buildParams(data)
    })

  delete: (url, ids) ->
    $.ajax(
      type: 'DELETE'
      url: url
      data: @_buildParams(planning_ids: ids)
    )

  addPlanningRow: (employee_id, work_item_id) ->
    $.ajax(
      url: "#{window.location.origin}#{window.location.pathname}/new"
      data: @_buildParams(
        employee_id: employee_id
        work_item_id: work_item_id
      )
    )

  _buildParams: (params) ->
    $.extend(utf8: '✓', params)
