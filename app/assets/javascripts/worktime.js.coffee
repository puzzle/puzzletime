app = window.App ||= {}

app.switchTimeFieldsVisibility = () ->
  type = $("#worktime_report_type").val()
  $("#worktime_work_date").prop('disabled', false)
  $("#worktime_work_date + span:has(.calendar)").show()

  switch type
    when "auto_start"
      $("#worktime_work_date").prop('disabled', true)
      $("#worktime_work_date").value = $.datepicker.formatDate(datepickerI18n().dateFormat, new Date())
      $("#worktime_work_date + span:has(.calendar)").hide()
      $("#worktime_hours").prop('disabled', true)
      $("#worktime_from_start_time").prop('disabled', false)
      $("#worktime_to_end_time").prop('disabled', true)
    when "start_stop_day"
      $("#worktime_hours").prop('disabled', true)
      $("#worktime_from_start_time").prop('disabled', false)
      $("#worktime_to_end_time").prop('disabled', false)
    else
      $("#worktime_from_start_time").prop('disabled', true)
      $("#worktime_to_end_time").prop('disabled', true)
      $("#worktime_hours").prop('disabled', false)

app.startProject = (id) ->
  $('#id').attr('value', id)
  copyWorktimeDetails('start')
  $('#start_project_form').submit()


app.stopAttendance = () ->
  copyWorktimeDetails('attendance')
  $('#stop_attendance_form').submit()


copyField = (fieldId, targetPrefix) ->
  field = $('#' + fieldId)
  if field
    $('#' + targetPrefix + '_' + fieldId).attr('value', field.val())

copyWorktimeDetails = (prefix) ->
  copyField('description', prefix)
  copyField('ticket', prefix)


$ ->
  $('body').on('click', '#attendanceStopper', (event) ->
    app.stopAttendance()
    event.preventDefault()
  )

  $('body').on('click', '#runningProjectStopper', (event) ->
    $('#stop_project_form').submit()
    event.preventDefault()
  )

  $('body').on('click', '[data-start-project]', (event) ->
    id = $(this).data('start-project')
    app.startProject(id)
    event.preventDefault()
  )

