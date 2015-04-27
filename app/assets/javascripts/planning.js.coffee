app = window.App ||= {}

$(document).on('click', '[data-switch-day]', (event) ->
  day = $(this).data('switch-day')
  $('#' + day).prop('checked', $('#' + day + '_am').prop('checked') &&
                               $('#' + day + '_pm').prop('checked'))
)

$(document).on('click', '[data-switch-half-day]', (event) ->
  day = $(this).data('switch-half-day')
  $('#' + day + '_am').prop('checked', $('#' + day).prop('checked'))
  $('#' + day + '_pm').prop('checked', $('#' + day).prop('checked'))
)
