app = window.App ||= {}
app.orderServices ||= {}

app.orderServices = new class
  init: ->
    @dateFilterChanged()

  dateFilterChanged: ->
    $('#order_services_filter_form').find('#start_date,#end_date')
      .datepicker('option', 'disabled', $('#period_shortcut').val())

$ ->
  app.orderServices.init()
