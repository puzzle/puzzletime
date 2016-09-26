app = window.App ||= {}
app.plannings ||= {}

app.plannings.service = do ->
  updateSelected: (url, planning) ->
    utf8 = planning.utf8
    planning.utf8 = undefined
    token = planning.authenticity_token
    planning.authenticity_token = undefined

    $.ajax({
      type: 'PATCH',
      url: url,
      data: {
        utf8: utf8,
        authenticity_token: token,
        planning: planning,
        items: app.plannings.selectable.getSelectedDays(),
      },
    }).fail((res) -> console.log('update error', res.status, res.statusText))

  deleteSelected: (url) ->
    console.log('delete')
