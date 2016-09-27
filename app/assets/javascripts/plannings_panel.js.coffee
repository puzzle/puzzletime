app = window.App ||= {}
app.plannings ||= {}

app.plannings.panel = new class
  panel = '.planning-panel'
  container = '.planning-calendar'
  positioning = false

  init: ->
    if @panel().length == 0
      return

    $(container).on('scroll', @position)

    @panel('.planning-definitive-group button').on('click', @definitiveChange)
    @panel('.planning-cancel').on('click', (event) =>
      $(event.target).blur()
      app.plannings.selectable.clear()
    )
    @panel('form').on('submit', @submit)
    @panel('.planning-delete').on('click', @deleteSelected)

  destroy: ->

  show: (selectedElements) ->
    @panel().show()
    @position()

    @hideErrors()
    @initPercent()
    @initDefinitive()

    hasExisting = app.plannings.selectable.selectionHasExistingPlannings()
    @panel('.planning-delete').css('visibility', if hasExisting then 'visible' else 'hidden')

  hide: ->
    $(panel).hide()

  showErrors: (errors) ->
    alerts = @panel('.alerts').empty().show()
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

  setPercent: (percent, focus, indefinite) ->
    input = @panel('#percent')
      .val(percent)
      .prop('placeholder', if indefinite then '?' else '')
    if focus then input.focus().select() else input.blur()

  initPercent: () ->
    values = app.plannings.selectable.getSelectedPercentValues()
    if values.length == 1
      @setPercent(values[0], true)
    else
      @setPercent('', false, true)

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

  position: =>
    if @panel().length == 0 || @panel().is(':hidden')
      return

    unless positioning
      requestAnimationFrame(() =>
        @panel().position({
          my: 'right top',
          at: 'right bottom',
          of: $(container).find('.ui-selected').last(),
          within: container
        })
        positioning = false
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
