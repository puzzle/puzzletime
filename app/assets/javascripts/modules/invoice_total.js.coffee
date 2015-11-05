app = window.App ||= {}

# Reloads the invoice total if form values change.
class app.InvoiceTotal
  constructor: (@form, @dateFields) ->
    @baseUrl = ->
      $(@form).data('preview-total-path')

    @params = ->
      $(@form).serialize()


  ## public methods

  reload: ->
    $.getScript("#{@baseUrl()}?#{@params()}")

  bind: ->
    self = this
    $(document).on('change', @form, (event) -> self.reload())
    $(document).on('blur', @dateFields, (event) -> self.reload())


new app.InvoiceTotal('form.invoice', 'input#invoice_period_from, input#invoice_period_to').bind()
