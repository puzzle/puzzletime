app = window.App ||= {}

app.worktimes = {}

app.worktimes.scrollSpeed = 300;
app.worktimes.activationEnabled = true;


app.worktimes.activateNavDayWithDate = (date) ->
  unless app.worktimes.activationEnabled
    return

  $('.worktimes .weeknav .day').removeClass('active')
  $('.worktimes .weeknav .day[data-date="' + date + '"]').addClass('active')


app.worktimes.activateFirstNavDay = ->
  unless app.worktimes.activationEnabled
    return

  $('.worktimes .weeknav .day').removeClass('active')
  $('.worktimes .weeknav .day:first-child').addClass('active')


app.worktimes.activateLastNavDay = ->
  unless app.worktimes.activationEnabled
    return

  $('.worktimes .weeknav .day').removeClass('active')
  $('.worktimes .weeknav .day:last-child').addClass('active')


app.worktimes.scrollToDayWithDate = (date) ->
  dateLabel = $('.worktimes .weekcontent .date-label[data-date="' + date + '"]')
  if dateLabel.size() is 0
    return

  offset = dateLabel.offset().top - $('.worktimes .weeknav').height() - 20;
  app.worktimes.scrollTo(offset, app.worktimes.activateNavDayWithDate, date)


app.worktimes.scrollTo = (offset, callback, date) ->
  # temporarly disable setting of .active on weeknav days
  app.worktimes.activationEnabled = false

  $('html, body').animate({scrollTop: offset},
    app.worktimes.scrollSpeed, undefined, (->
      app.worktimes.activationEnabled = true
      callback.call(this, date)

      if date
        # hightlight entries
        entries = $('.worktimes .weekcontent .date-label[data-date="' + date + '"], ' + \
          '.worktimes .weekcontent .entry[data-date="' + date + '"]')
        entries.addClass('highlight')
        setTimeout((-> entries.removeClass('highlight')), 400)
    ))

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

$ ->

  $('#new_ordertime_link').click (e) ->
    e.preventDefault()
    window.location.href = $(this). attr('href') + '?work_date=' + $("#week_date").val();

  $('#new_other_ordertime_link').click (e) ->
    e.preventDefault()
    window.location.href = $(this). attr('href') + '&work_date=' + $("#week_date").val();

  if $('.worktimes').size()
    $('.worktimes .weekcontent .date-label').
      waypoint({ handler: (direction) ->
        if direction == 'down'
          app.worktimes.activateNavDayWithDate($(this).data('date'))
        else if direction == 'up' && $(this).prev().size()
          app.worktimes.activateNavDayWithDate($(this).prev().data('date'))
      , offset: -> $('.weeknav').height() })


    $('.worktimes .weeknav .day').on('click', (event) ->
      event.preventDefault();
      date = new Date($(event.currentTarget).data('date'))
      $("#week_date").datepicker({dateFormat: 'yyyy-mm-dd'}).datepicker('setDate', date)
      app.worktimes.scrollToDayWithDate($(event.currentTarget).data('date'))
    )

    $('.worktimes .weeknav-container').waypoint('sticky')

    $("#week_date").datepicker
      showWeek: true,
      changeYear: true
      showButtonPanel: true
      onSelect: (date, instance) ->
        window.location = "/worktimes?week_date=" + date
        return

    selectedDate = $('.worktimes').data('selectedDate')
    if selectedDate && $('.worktimes .weeknav .day[data-date="' + selectedDate + '"]').size()
      $('.worktimes .weeknav .day[data-date="' + selectedDate + '"]').click()

  # toggle from/to and hour input fields
  toggle = (selector_id, disable) ->
    $(selector_id).prop('disabled', disable)
    if disable
      $(selector_id).val('')

  $('#ordertime_hours').blur ->
    toggle('#ordertime_from_start_time', $(this).val())
    toggle('#ordertime_to_end_time', $(this).val())
  $('#ordertime_from_start_time').blur ->
    toggle('#ordertime_hours', $(this).val() || $('#ordertime_to_end_time').val())
  $('#ordertime_to_end_time').blur ->
    toggle('#ordertime_hours', $(this).val() || $('#ordertime_from_start_time').val())
  $('#absencetime_hours').blur ->
    toggle('#absencetime_from_start_time', $(this).val())
    toggle('#absencetime_to_end_time', $(this).val())
  $('#absencetime_from_start_time').blur ->
    toggle('#absencetime_hours', $(this).val() || $('#absencetime_to_end_time').val())
  $('#absencetime_to_end_time').blur ->
    toggle('#absencetime_hours', $(this).val() || $('#absencetime_from_start_time').val())


  if $('#absencetime_create_multi').val()
    showMultiAbsence(null)
  else if $('#new_absencetime').length
    showRegularAbsence(null)

  $('#multi_absence_link').click(showMultiAbsence)
  $('#regular_absence_link').click(showRegularAbsence)
