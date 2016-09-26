app = window.App ||= {}
app.plannings ||= {}

app.plannings.panel = do ->
  panel = '.planning-panel'
  container = '.planning-calendar'

  setPercent = (percent) ->
    $(panel).find('#percent').val(percent)

  setDefinitive = (definitive) ->
    $(panel).find('.planning-definitive').toggleClass('active', definitive == true)
    $(panel).find('.planning-provisional').toggleClass('active', definitive == false)

    value = if definitive? then definitive.toString() else ''
    $(panel).find('#definitive').val(value)


  definitiveChange = (event) ->
    source = $(event.target).hasClass('planning-definitive')
    current = $(panel).find('#definitive').val()
    setDefinitive(if source.toString() == current then null else source)

  position = ->
    if $(panel).length == 0 || $(panel).is(':hidden')
      return

    $(panel).position({
      my: 'right top',
      at: 'right bottom',
      of: $(container).find('.ui-selected').last(),
      within: container
    })

  closeOnEscape = (event) ->
    if event.key == "Escape"
      app.plannings.panel.close()

  submit = (event) ->
    event.preventDefault()
    app.plannings.panel.hideErrors()
    data = $(event.target).serializeArray()
      .reduce(((prev, curr) -> prev[curr.name] = curr.value; prev), {})
    app.plannings.service.updateSelected(getFormAction(), data)

  deleteSelected = (event) ->
    event.preventDefault()
    # TODO: show confirmation dialog (or make it work via link_to confirm)
    app.plannings.service.deleteSelected(getFormAction())

  getFormAction = ->
    $(panel).find('form').prop('action')

  show: (selectedElements) ->
    $(panel)
      .show()
      .on('click', (event) -> event.stopPropagation())
    position()

    app.plannings.panel.hideErrors()
    setPercent('')
    setDefinitive(true)

    $(panel).find('#percent').focus()

  hide: ->
    $(panel).hide()

  close: ->
    app.plannings.panel.hide()
    app.plannings.selectable.clear()

  showErrors: (errors) ->
    alerts = $(panel).find('.alerts').empty().show()
    if errors && errors.length > 0
      errors.forEach((error) ->
        alerts.append($('<div class="alert alert-danger">', text: error)))
    else
      alerts.append($('<div class="alert alert-danger">Ein Fehler ist aufgetreten</div>'))
    position()

  hideErrors: ->
    $(panel).find('.alert').hide()

  init: ->
    if $(panel).length == 0
      return

    $(document).on('keyup', closeOnEscape)

    ticking = false
    $(container).on('scroll', () ->
      requestAnimationFrame(() -> position(); ticking = false) unless ticking
      ticking = true
    )

    $(panel).find('.planning-definitive-group button').on('click', definitiveChange)
    $(panel).find('.planning-cancel').on('click', (event) ->
      $(event.target).blur()
      app.plannings.panel.close()
    )
    $(panel).find('form').on('submit', submit)
    $(panel).find('.planning-delete').on('click', deleteSelected)

  destroy: ->
    $(document).off('keyup', closeOnEscape)

$ ->
  app.plannings.panel.destroy()
  app.plannings.panel.init()
