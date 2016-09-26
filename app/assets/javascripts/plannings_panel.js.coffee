app = window.App ||= {}
app.plannings ||= {}

app.plannings.panel = new class
  panel = '.planning-panel'
  container = '.planning-calendar'
  ticking = false

  setPercent = (percent, focus, indefinite) ->
    input = $(panel).find('#percent')
      .val(percent)
      .prop('placeholder', if indefinite then '?' else '')
    if focus then input.focus().select() else input.blur()

  initPercent = () ->
    values = app.plannings.selectable.getSelectedPercentValues()
    if values.length == 1
      setPercent(values[0], true)
    else
      setPercent('', false, true)

  setDefinitive = (definitive) ->
    $(panel).find('.planning-definitive').toggleClass('active', definitive == true)
    $(panel).find('.planning-provisional').toggleClass('active', definitive == false)

    value = if definitive? then definitive.toString() else ''
    $(panel).find('#definitive').val(value)

  initDefinitive = ->
    values = app.plannings.selectable.getSelectedDefinitiveValues()
    if values.length == 1
      setDefinitive(if values[0] == null then true else values[0])
    else
      setDefinitive(null)

  definitiveChange = (event) ->
    source = $(event.target).hasClass('planning-definitive')
    current = $(panel).find('#definitive').val()
    setDefinitive(if source.toString() == current then null else source)

  position = ->
    if $(panel).length == 0 || $(panel).is(':hidden')
      return

    unless ticking
      requestAnimationFrame((() ->
        $(panel).position({
          my: 'right top',
          at: 'right bottom',
          of: $(container).find('.ui-selected').last(),
          within: container
        })
        ticking = false
      ))
    ticking = true

  deleteSelected = (event) ->
    event.preventDefault()
    # TODO: show confirmation dialog (or make it work via link_to confirm)
    app.plannings.service.deleteSelected(getFormAction())

  getFormAction = ->
    $(panel).find('form').prop('action')

  show: (selectedElements) =>
    $(panel)
      .show()
      .on('click', (event) -> event.stopPropagation())
    position()

    @hideErrors()
    initPercent()
    initDefinitive()

    if app.plannings.selectable.selectionHasExistingPlannings()
      $(panel).find('.planning-delete').css('visibility', 'visible')
    else
      $(panel).find('.planning-delete').css('visibility', 'hidden')

  hide: ->
    $(panel).hide()

  close: =>
    @hide()
    app.plannings.selectable.clear()

  closeOnEscape: (event) =>
    if event.key == "Escape"
      @close()

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

  submit: (event) =>
    event.preventDefault()
    @hideErrors()
    data = $(event.target).serializeArray()
    .reduce(((prev, curr) -> prev[curr.name] = curr.value; prev), {})
    app.plannings.service.updateSelected(getFormAction(), data)

  init: ->
    if $(panel).length == 0
      return

    $(document).on('keyup', @closeOnEscape)
    $(container).on('scroll', position)

    $(panel).find('.planning-definitive-group button').on('click', definitiveChange)
    $(panel).find('.planning-cancel').on('click', (event) =>
      $(event.target).blur()
      @close()
    )
    $(panel).find('form').on('submit', @submit)
    $(panel).find('.planning-delete').on('click', deleteSelected)

  destroy: ->
    $(document).off('keyup', @closeOnEscape)

$ ->
  app.plannings.panel.destroy()
  app.plannings.panel.init()
