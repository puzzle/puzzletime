$(document).ready ->
  $(".workload_report").on("ajax:success", (e, data, status, xhr) ->
    $('.list [data-toggle-visibility]').each((index, element) ->
      new window.App.VisibilityToggler(element)
    )
  )