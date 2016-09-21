app = window.App ||= {}
app.plannings ||= {}

app.plannings.service = do ->
  updateSelected: (planning) ->
    utf8 = planning.utf8
    planning.utf8 = undefined
    token = planning.authenticity_token
    planning.authenticity_token = undefined

    $.ajax({
      type: 'PATCH',
#      url: '',
      data: {
        utf8: utf8,
        authenticity_token: token,
        planning: planning,
        create: app.plannings.selectable.getEmptySelectedDays(),
        update: app.plannings.selectable.getSelectedIds()
      },
    }).fail((res) -> console.log('update error', res.status, res.statusText))

  deleteSelected: ->
    console.log('delete')
