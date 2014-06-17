app = window.App ||= {}

app.worktimes = {}

app.worktimes.scrollSpeed = 300;


app.worktimes.activateNavDayWithDate = (date) ->
  $('.worktimes .weeknav .day').removeClass('active')
  $('.worktimes .weeknav .day[data-date="' + date + '"]').addClass('active')


app.worktimes.activateFirstNavDay = ->
  $('.worktimes .weeknav .day').removeClass('active')
  $('.worktimes .weeknav .day:first-child').addClass('active')


app.worktimes.activateLastNavDay = ->
  $('.worktimes .weeknav .day').removeClass('active')
  $('.worktimes .weeknav .day:last-child').addClass('active')


app.worktimes.scrollToDayWithDate = (date) ->
  dateLabel = $('.worktimes .weekcontent .date-label[data-date="' + date + '"]')

  if dateLabel.hasClass('empty')
    # no entries for this date available
    if dateLabel.prevAll('.date-label:not(.empty)').size() is 0
      # scroll to beginning
      offset = $('.worktimes .weekcontent').offset().top + $('.worktimes .weeknav').height() - 20;
      $('html, body').animate({scrollTop: offset},
        app.worktimes.scrollSpeed, undefined, (-> app.worktimes.activateFirstNavDay()))
      return
    else if dateLabel.nextAll('.date-label:not(.empty)').size() is 0
      # scroll to end
      offset = $('body').height()
      $('html, body').animate({scrollTop: offset},
        app.worktimes.scrollSpeed, undefined, (-> app.worktimes.activateLastNavDay()))
      return
    else
      # scroll to previous non-empty entry
      dateLabel = dateLabel.prevAll('.date-label:not(.empty)').first()
      date = dateLabel.data('date')

  # offset = $('.worktimes .weekcontent').scrollTop() -
  offset = dateLabel.offset().top - $('.worktimes .weeknav').height() - 20;
  $('html, body').animate({scrollTop: offset},
    app.worktimes.scrollSpeed, undefined, (->
      app.worktimes.activateNavDayWithDate(date)

      # hightlight entries
      entries = $('.worktimes .weekcontent .date-label[data-date="' + date + '"], ' + \
        '.worktimes .weekcontent .entry[data-date="' + date + '"]')
      entries.addClass('highlight')
      setTimeout((-> entries.removeClass('highlight')), 1100)
    ))


$ ->
  $('.worktimes .weekcontent .entry').waypoint( \
    (direction) -> app.worktimes.activateNavDayWithDate($(this).data('date'))
    ,
    { context: '.worktimes .weekcontent' }
  )

  $('.worktimes .weeknav .day').on('click', (event) ->
    event.preventDefault();
    app.worktimes.scrollToDayWithDate($(event.currentTarget).data('date'))
  )

  $('.worktimes .weeknav').waypoint('sticky')
