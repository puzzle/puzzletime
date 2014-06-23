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

  if dateLabel.hasClass('empty')
    # no entries for this date available
    if dateLabel.prevAll('.date-label:not(.empty)').size() is 0
      # scroll to beginning
      offset = $('.worktimes .weekcontent').offset().top + $('.worktimes .weeknav').height() - 20;
      app.worktimes.scrollTo(offset, app.worktimes.activateFirstNavDay)
      return
    else
      # scroll to previous non-empty entry
      dateLabel = dateLabel.prevAll('.date-label:not(.empty)').first()
      date = dateLabel.data('date')

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
        setTimeout((-> entries.removeClass('highlight')), 500)
    ))


$ ->
  if $('.worktimes').size()
    $('.worktimes .weekcontent .entry,'+
      '.worktimes .weekcontent .date-label:not(.empty)').waypoint( \
        (direction) -> app.worktimes.activateNavDayWithDate($(this).data('date')))

    $('.worktimes .weeknav .day').on('click', (event) ->
      event.preventDefault();
      app.worktimes.scrollToDayWithDate($(event.currentTarget).data('date'))
    )

    $('.worktimes .weeknav').waypoint('sticky')

    $("#date_picker_week_date").datepicker onSelect: (date, instance) ->
      window.location = "/worktimes?week_date=" + date
      return

    selectedDate = $('.worktimes').data('selectedDate')
    if selectedDate && $('.worktimes .weeknav .day[data-date="' + selectedDate + '"]').size()
      $('.worktimes .weeknav .day[data-date="' + selectedDate + '"]').click()
