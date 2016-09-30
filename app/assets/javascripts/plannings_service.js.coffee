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
      data: Object.assign(utf8: '✓', data)
    })

  delete: (url, ids) ->
    $.ajax(
      type: 'DELETE'
      url: url
      data:
        utf8: '✓'
        planning_ids: ids
    )

  addPlanningRow: (employee_id, work_item_id) ->
    return $.ajax(
      url: "#{window.location.origin}#{window.location.pathname}/new"
      data:
        utf8: '✓'
        employee_id: employee_id
        work_item_id: work_item_id
    )
