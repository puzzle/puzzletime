app = window.App ||= {}

# Reloads selectable employees according to given timeperiod
class app.InvoiceEmployees
  constructor: () ->

  render_checkboxes = (employees) ->
    checkbox_container = $('label[for="invoice_employee_ids"]').next()
    content = HandlebarsTemplates['invoice_employee_checkbox'](employees)
    checkbox_container.html(content)

  from_date = () ->
    return datepicker_date('input#invoice_period_from')

  to_date = () ->
    return datepicker_date('input#invoice_period_to')

  datepicker_date = (input_field) ->
    $(input_field).val()

  load_employees = ->
    from = from_date
    to = to_date
    order_id = $('input#order_id').val()
    url = '/orders/' + order_id + '/employees'
    $.get(url, { period_from: from, period_to: to}).done (data) ->
      render_checkboxes(data)

  reload = ->
    load_employees()

  # public methods
  bind: ->
    $(document).on('change', 'input#invoice_period_from', (event) -> reload())
    $(document).on('change', 'input#invoice_period_to', (event) -> reload())

new app.InvoiceEmployees().bind()
