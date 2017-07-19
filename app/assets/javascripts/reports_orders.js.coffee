app = window.App ||= {}

app.reportsOrders = new class
  init: ->
    @dateFilterChanged()

  dateFilterChanged: ->
    $('.order_reports form[role="filter"]').find('#start_date,#end_date')
      .datepicker('option', 'disabled', $('#period_shortcut').val())

$(document).on('ajax:success', '.order_reports form[role="filter"]', ->
  app.reportsOrders.init()
)

$(document).on 'turbolinks:load', ->
  app.reportsOrders.init()
