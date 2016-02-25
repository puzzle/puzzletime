app = window.App ||= {}

# Reloads selectable employees according to given timeperiod
class app.InvoiceEmployees
  constructor: () ->
    @checkbox_container = ->
      $('label[for="invoice_employee_ids2"]').next()

  employee_checkbox = (id, firstname, lastname) ->
    $('div')

  employee_checkboxes = (data) ->
    console.log(data)

  load_employees = ->
    #from = $('input#invoice_period_from')
    #to = $('input#invoice_period_to')
    order_id = $('input#order_id').attr('value')
    url = '/orders/' + order_id + '/employees'
    $.get(url, (data) ->
      console.log(data)
      #employee_checkboxes(data)
    )

  reload = ->
    console.log('yay!')
    load_employees()

  ## public methods
  bind: ->
    $(document).on('ready', -> reload())
    $(document).on('blur', 'input#invoice_period_from', (event) -> reload())
    $(document).on('blur', 'input#invoice_period_to', (event) -> reload())

#new app.InvoiceEmployees().bind()
