#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


app = window.App ||= {}

app.worktimes = new class
  scrollSpeed = 300
  activationEnabled = true
  worktimesWaypoint = null
  headerOffset = 0

  toggle = (selector, disable) ->
    $(selector).prop('disabled', disable)
    $(selector).val('') if disable

  # show regular absence on load, toggle when clicking on multi absence link
  showMultiAbsence = (e) ->
    $('#absencetime_create_multi').val('true')
    $('#single').hide()
    $('#multi').show()
    e.preventDefault() if e

  showRegularAbsence = (e) ->
    $('#absencetime_create_multi').val('')
    $('#single').show()
    $('#multi').hide()
    e.preventDefault() if e

  init: ->
    @bind()
    @initWaypoint()
    @initScroll()

  container: (selector) ->
    if selector
      $(selector, '.worktimes-container')
    else
      $('.worktimes-container')

  bind: ->
    $('#new_ordertime_link').click (e) ->
      e.preventDefault()
      window.location.href = "#{$(this).attr('href')}?work_date=#{$('#week_date').val()}"

    $('#new_other_ordertime_link').click (e) ->
      e.preventDefault()
      window.location.href = "#{$(this).attr('href')}&work_date=#{$('#week_date').val()}"

    if @container().length
      $('#week_date').on 'change', (event) ->
        date = event.target.value
        window.location = "/worktimes?week_date=#{date}"
        return

    $('#ordertime_hours').blur ->
      toggle('#ordertime_from_start_time', @value)
      toggle('#ordertime_to_end_time', @value)
    $('#ordertime_from_start_time').blur ->
      toggle('#ordertime_hours', @value || $('#ordertime_to_end_time').val())
    $('#ordertime_to_end_time').blur ->
      toggle('#ordertime_hours', @value || $('#ordertime_from_start_time').val())
    $('#absencetime_hours').blur ->
      toggle('#absencetime_from_start_time', @value)
      toggle('#absencetime_to_end_time', @value)
    $('#absencetime_from_start_time').blur ->
      toggle('#absencetime_hours', @value || $('#absencetime_to_end_time').val())
    $('#absencetime_to_end_time').blur ->
      toggle('#absencetime_hours', @value || $('#absencetime_from_start_time').val())

    if $('#absencetime_create_multi').val()
      showMultiAbsence(null)
    else if $('#new_absencetime').length
      showRegularAbsence(null)

    $('#multi_absence_link').click(showMultiAbsence)
    $('#regular_absence_link').click(showRegularAbsence)

  initWaypoint: ->
    if worktimesWaypoint
      worktimesWaypoint.destroy()
      worktimesWaypoint = null

    headerOffset = (if $(window).width() > 768 then $('header').height() else 0) #set offset of header

    if @container().length
      @container('.weekcontent .date-label')
        .waypoint(
          handler: (direction) ->
            if direction == 'down'
              app.worktimes.activateNavDayWithDate($(this.element).data('date'))
            else if direction == 'up' && $(this.element).prev().length
              app.worktimes.activateNavDayWithDate($(this.element).prev().data('date'))
          ,
          offset: -> $('.weeknav').height() + headerOffset
        )

      @container('.weeknav .day').on('click', (e) =>
        e.preventDefault()
        date = new Date($(e.currentTarget).data('date'))
        $('#week_date').datepicker('setDate', date)
        @scrollToDayWithDate($(e.currentTarget).data('date'))
      )

      unless Modernizr.csspositionsticky
        setTimeout =>
          worktimesWaypoint = new Waypoint.Sticky
            element: @container()[0]

  initScroll: ->
    if @container().length && !$('.alert:not(.alert-success)', 'main').length
      selectedDate = @container().data('selectedDate')
      return unless selectedDate
      day = @container(".weeknav .day[data-date=\"#{selectedDate}\"]")
      day.click() if day.length


  activate: (selector) ->
    unless activationEnabled
      return

    @container('.weeknav .day')
      .removeClass('active')
      .filter(selector)
      .addClass('active')

  activateNavDayWithDate: (date) =>
    @activate("[data-date=\"#{date}\"]")

  activateFirstNavDay: ->
    @activate(':first-child')

  activateLastNavDay: ->
    @activate(':last-child')

  scrollToDayWithDate: (date) ->
    dateLabel = @container(".weekcontent .date-label[data-date=\"#{date}\"]")
    if dateLabel.length is 0
      return

    offset = dateLabel.offset().top - @container('.weeknav').height() - 20 - headerOffset
    @scrollTo(offset, @activateNavDayWithDate, date)

  scrollTo: (offset, callback, date) ->
    # temporarly disable setting of .active on weeknav days
    activationEnabled = false

    $('html, body').animate({ scrollTop: offset },
      scrollSpeed, undefined, =>
        activationEnabled = true
        callback(date)

        if date
          # hightlight entries
          entries = @container(
            '.weekcontent .date-label[data-date="' + date + '"], ' +
            '.weekcontent .entry[data-date="' + date + '"]')
          entries.addClass('highlight')
          setTimeout((-> entries.removeClass('highlight')), 400)
      )

$(document).on 'turbolinks:load', ->
  app.worktimes.init()
