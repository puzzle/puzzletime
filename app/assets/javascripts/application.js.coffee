# Place your application-specific JavaScript functions and classes here
# This file is automatically included by javascript_include_tag :defaults
#
#= require jquery
#= require jquery.turbolinks
#= require jquery_ujs
#= require jquery-ui/datepicker
#= require jquery-ui-datepicker-i18n
#= require jquery-ui/autocomplete
#= require selectize
#= require waypoints
#= require waypoints-sticky
#= require bootstrap/modal
#= require bootstrap/tooltip
#= require bootstrap/button
#= require bootstrap/alert
#= require_self
#= require_tree ./modules
# after self to disable links
#= require nested_form_fields
#= require modal_create
#= require worktimes
#= require workload_report
#= require week_datepicker
#= require work_item_autocomplete
#= require planning
#= require orders
#= require order_contacts
#= require accounting_posts
#= require turbolinks
#= require progress_bar


app = window.App ||= {}

if typeof String.prototype.endsWith isnt 'function'
  String.prototype.endsWith = (suffix) ->
    return this.indexOf(suffix, this.length - suffix.length) isnt -1


################################################################
# because of turbolinks.jquery, do bind ALL document events here

# wire up toggle links
$(document).on('click', '[data-toggle]', (event) ->
  id = $(this).data('toggle')
  $('#' + id).slideToggle(200)
  event.preventDefault()
)

# wire up direct submit fields
$(document).on('change', '[data-submit]', (event) ->
  $(this).closest('form').submit()
)

# wire up tooltips
$(document).tooltip({ selector: '[data-toggle=tooltip]', placement: 'top', html: true })

# wire up searchable form fields for dynamically added nested form fields
$(document).on "fields_added.nested_form_fields", (event,param) ->
  $('select.searchable').selectize()

# show alert if ajax requests fail
$(document).on('ajax:error', (event, xhr, status, error) ->
  alert('Sorry, something went wrong\n(' + error + ')'))



################################################################
# only bind events for non-document elemenets in $ ->
$ ->
  # wire up autocompletes
  $('[data-autocomplete=work_item]').each(app.workItemAutocomplete)

  # wire up selectize
  $('select.searchable:not([multiple])').selectize(selectOnTab: true)
  $('select[multiple].searchable').selectize(plugins: ['remove_button'], selectOnTab: true)

  # wire up toggle buttons
  $('[data-toggle=buttons]').button()

  # wire up visibility toggler elements
  $('[data-toggle-visibility]').each((index, element) ->
    new app.VisibilityToggler(element)
  )

  # wire up disabled links. Bind on body to handle bubbling event before document
  $('body').on('click', 'a.disabled', (event) ->
    event.preventDefault()
    event.stopImmediatePropagation()
    event.stopPropagation()
  )

  # wire up disable-dependents
  $('[type=radio][data-disable-dependents]:checked').each((i, e) -> toggleRadioDependents(e))

  # set initial focus
  $('.initial-focus, .initial-focus input').focus()
