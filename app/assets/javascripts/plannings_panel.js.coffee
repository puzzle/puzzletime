app = window.App ||= {}
app.plannings ||= {}

app.plannings.panel = new class
  panel = '.planning-panel'
  container = '.planning-calendar'
  positioning = false
  focusPercentOnShow = false

  init: ->
    return if @panel().length == 0
    @bindListeners()

  destroy: ->
    @bindListeners(true)

  bindListeners: (unbind) ->
    func = if unbind then 'off' else 'on'

    $('main')[func]('scroll', @position)

    @panel('.planning-definitive-group button')[func]('click', @definitiveChange)
    @panel('#repetition')[func]('click', @repetitionChange)
    @panel('.planning-cancel')[func]('click', @cancel)
    @panel('form')[func]('submit', @submit)
    @panel('.planning-delete')[func]('click', @deleteSelected)

  show: (selectedElements) ->
    @position()

    @hideErrors()
    @initPercent()
    @initDefinitive()
    @initRepetition()

    hasExisting = app.plannings.selectable.selectionHasExistingPlannings()
    @panel('.planning-delete').css('visibility', if hasExisting then 'visible' else 'hidden')

  hide: ->
    $(panel).hide()

  cancel: (event) =>
    $(event.target).blur()
    app.plannings.selectable.clear()

  showErrors: (errors) ->
    alerts = @panel('.alerts').empty()
    if errors?.length
      alert = '<div class="alert alert-danger">'
      if errors.length > 1
        alert += '<ul>'
        errors.forEach((error) -> alert += "<li>#{error}</li>")
        alert += '</ul>'
      else
        alert += errors[0]
      alert += '</div>'
      alerts.append($(alert))
    else
      alerts.append($('<div class="alert alert-danger">Ein Fehler ist aufgetreten</div>'))
    alerts.show()
    @position()

  hideErrors: ->
    @panel('.alert').hide()

  submit: (event) =>
    event.preventDefault()
    @hideErrors()
    data = $(event.target).serializeArray()
      .reduce(((prev, curr) -> prev[curr.name] = curr.value; prev), {})
    app.plannings.service.updateSelected(@getFormAction(), data)

  deleteSelected: (event) =>
    if confirm('Bist du sicher, dass du die selektierte Planung löschen willst?')
      event.preventDefault()
      app.plannings.service.delete(
        @getFormAction(),
        app.plannings.selectable.getSelectedPlanningIds()
      )

  getFormAction: ->
    @panel('form').prop('action')

  setPercent: (percent, indefinite) ->
    @panel('#percent')
      .val(percent)
      .prop('placeholder', if indefinite then '?' else '')

  initPercent: () ->
    values = app.plannings.selectable.getSelectedPercentValues()
    percent = if values.length == 1 then values[0] else ''
    @setPercent(percent, values.length > 1)
    focusPercentOnShow = values.length == 1

  setDefinitive: (definitive) ->
    @panel('.planning-definitive').toggleClass('active', definitive == true)
    @panel('.planning-provisional').toggleClass('active', definitive == false)

    value = if definitive? then definitive.toString() else ''
    @panel('#definitive').val(value)

  initDefinitive: ->
    values = app.plannings.selectable.getSelectedDefinitiveValues()
    if values.length == 1
      @setDefinitive(if values[0] == null then true else values[0])
    else
      @setDefinitive(null)

  definitiveChange: (event) =>
    source = $(event.target).hasClass('planning-definitive')
    current = @panel('#definitive').val()
    @setDefinitive(if source.toString() == current then null else source)

  initRepetition: () ->
    @panel('#repetition').prop('checked', false)
    @panel('.planning-repetition-group').hide()
    @panel('#repeat_until').val('')

  repetitionChange: (event) =>
    enabled = $(event.target).prop('checked')
    @panel('.planning-repetition-group')[if enabled then 'show' else 'hide']()
    @panel('#repeat_until').val('')

  position: (e) =>
    hasSelection = () -> $(container).find('.ui-selected').length
    return if @panel().length == 0 ||
      (e?.type == 'scroll' && @panel().is(':hidden')) ||
      !hasSelection()

    unless positioning
      requestAnimationFrame(() =>
        if !hasSelection()
          positioning = false
          return

        wasHidden = @panel().is(':hidden')

        @panel().show().position({
          my: 'right top'
          at: 'right bottom'
          of: $(container).find('.ui-selected').last()
          within: 'main'
          collision: 'flipfit flipfit'
        })
        positioning = false

        if wasHidden
          if focusPercentOnShow
            @panel('#percent').focus().select()
          else
            @panel('#percent').blur()
      )
    positioning = true

  panel: (selector) ->
    if selector
      $(selector, panel)
    else
      $(panel)

$ ->
  app.plannings.panel.destroy()
  app.plannings.panel.init()
