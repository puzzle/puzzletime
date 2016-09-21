app = window.App ||= {}
app.plannings ||= {}

app.plannings.panel = do ->
  panel = '.planning-panel'
  container = '.planning-calendar'

  position = ->
    if $(panel).length == 0 || $(panel).is(':hidden')
      return

    $(panel).position({
      my: 'right top',
      at: 'right bottom',
      of: $(container).find('.ui-selected').last(),
      within: container
    })

  cancel = ->
    app.plannings.panel.hide()
    app.plannings.selectable.clear()

  cancelOnEscape = (event) ->
    if event.key == "Escape"
      cancel()

  submit = (event) ->
    event.preventDefault()
    console.log('submit')

  deleteSelected = (event) ->
    event.preventDefault()
    console.log('delete')

  show: (selectedElements) ->
    $(panel)
      .show()
      .on('click', (event) -> event.stopPropagation())
    position()

  hide: ->
    $(panel).hide()

  init: ->
    if $(panel).length == 0
      return

    $(document).on('keyup', cancelOnEscape)
    $(container).on('scroll', position)

    $(panel).find('.planning-cancel').on('click', (event) ->
      $(event.target).blur()
      cancel()
    )
    $(panel).find('form').on('submit', submit)
    $(panel).find('.planning-delete').on('click', deleteSelected)

  destroy: ->
    $(document).off('keyup', cancelOnEscape)

$ ->
  app.plannings.panel.destroy()
  app.plannings.panel.init()
