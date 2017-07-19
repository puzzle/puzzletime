# Place your application-specific JavaScript functions and classes here
# This file is automatically included by javascript_include_tag :defaults
#
#= require jquery3
#= require jquery_ujs
#= require jquery-ui/widgets/datepicker
#= require jquery-ui/widgets/autocomplete
#= require jquery-ui/widgets/selectable
#= require selectize
#= require bootstrap/modal
#= require bootstrap/tooltip
#= require bootstrap/button
#= require bootstrap/alert
#= require vendor/jquery-ui-datepicker-i18n
#= require vendor/modernizr-custom
#= require vendor/waypoints/jquery.waypoints
#= require vendor/waypoints/shortcuts/sticky
#= require vendor/waypoints/shortcuts/inview
#= require_self
#= require_tree ./modules
# after self to disable links
#= require nested_form_fields
#= require modal_create
#= require datepicker
#= require worktimes
#= require plannings
#= require plannings_panel
#= require plannings_selectable
#= require plannings_service
#= require orders
#= require order_contacts
#= require order_services
#= require accounting_posts
#= require reports_orders
#= require turbolinks


app = window.App ||= {}

if typeof String.prototype.endsWith isnt 'function'
  String.prototype.endsWith = (suffix) ->
    return this.indexOf(suffix, this.length - suffix.length) isnt -1

Object.defineProperty(Object.prototype, 'do', value: (callback) ->
  callback.call(this, this)
  this
)

if typeof Object.assign != 'function'
  Object.assign = (target) ->
    'use strict'
    unless target?
      throw new TypeError('Cannot convert undefined or null to object')
    output = Object(target)
    index = 1
    while index < arguments.length
      source = arguments[index]
      if source != undefined and source != null
        for nextKey of source
          if source.hasOwnProperty(nextKey)
            output[nextKey] = source[nextKey]
      index++
    output

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
$(document).tooltip({
  selector: '[data-toggle=tooltip]',
  container: 'body',
  placement: 'top',
  html: true
})

# wire up searchable form fields for dynamically added nested form fields
$(document).on "fields_added.nested_form_fields", (event,param) ->
  $('select.searchable').selectize()

# show alert if ajax requests fail
$(document).on('ajax:error', (event, xhr, status, error) ->
  alert('Sorry, something went wrong\n(' + error + ')'))


################################################################
# only bind events for non-document elements in $ ->
$(document).on('turbolinks:load', ->
  # wire up selectize
  $('select.searchable:not([multiple])').selectize(selectOnTab: true)
  $('select[multiple].searchable').selectize(plugins: ['remove_button'], selectOnTab: true)

  # wire up toggle buttons
  $('[data-toggle=buttons]').button()

  # wire up disabled links. Bind on body to handle bubbling event before document
  $('body').on('click', 'a.disabled', (event) ->
    event.preventDefault()
    event.stopImmediatePropagation()
    event.stopPropagation()
  )

  # set initial focus
  $('.initial-focus, .initial-focus input').focus()
  setTimeout(-> $('.initial-focus.selectized').next('.selectize-control').find('input').focus())
)
