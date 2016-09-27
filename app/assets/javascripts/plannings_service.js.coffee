app = window.App ||= {}
app.plannings ||= {}

app.plannings.service = new class
  updateSelected: (url, planning) ->
    utf8 = planning.utf8
    planning.utf8 = undefined
    token = planning.authenticity_token
    planning.authenticity_token = undefined

    return $.ajax({
      type: 'PATCH',
      url: url,
      data: {
        utf8: utf8,
        authenticity_token: token,
        planning: planning,
        items: app.plannings.selectable.getSelectedDays(),
      },
    }).fail((res) -> console.log('update error', res.status, res.statusText))

  delete: (url, ids) ->
    $.ajax(
      type: 'DELETE'
      url: url
      data:
        planning_ids: ids
    )

  addPlanningRow: (employee_id, work_item_id) ->
    return $.ajax(
      url: "#{window.location}/new"
      data:
        employee_id: employee_id
        work_item_id: work_item_id
    )
