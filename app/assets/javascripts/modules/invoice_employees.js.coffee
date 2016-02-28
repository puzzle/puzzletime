app = window.App ||= {}

# Reloads selectable employees according to given timeperiod
class app.InvoiceEmployees
  constructor: () ->

  employee_checkboxes = (employees) ->
    content = ''
    $.each(employees, ->
      content += HandlebarsTemplates['invoice_employee_checkbox'](this)
    )
    return content

  render_checkboxes = (employees) ->
    checkbox_container = $('label[for="invoice_employee_ids2"]').next()
    if employees.length == 0
      checkbox_container.html('keine Buchungen in der gewählten Periode vorhanden')
    else
      content = employee_checkboxes(employees)
      checkbox_container.html(content)

  from_date = () ->
    #$('input#invoice_period_from').datepicker('getDate')
    return '01.01.2016'

  to_date = () ->
    #$('input#invoice_period_to')
    return '01.01.2017'

  load_employees = ->
    from = from_date
    to = to_date
    order_id = $('input#order_id').attr('value')
    url = '/orders/' + order_id + '/employees'
    $.get(url, { period_from: from, period_to: to}).done (data) ->
      render_checkboxes(data)

  reload = ->
    load_employees()

  # public methods
  bind: ->
    $(document).on('ready', -> reload())
    $(document).on('blur', 'input#invoice_period_from', (event) -> reload())
    $(document).on('blur', 'input#invoice_period_to', (event) -> reload())

new app.InvoiceEmployees().bind()
