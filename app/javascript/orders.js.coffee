#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.


renderIconItem = (item, escape) ->
  '<div><span class="glyphicon glyphicon-' + item.value + '"></span> ' + escape(item.value) + '</div>'

renderStyleItem = (item, escape) ->
  '<div><span class="label label-' + item.value + '">' + escape(item.value) + '</span></div>'



################################################################
# because of turbolinks.jquery, do bind ALL document events here

$(document).on('click', '[data-submit-form]', (event) ->
  form_id = $(this).attr('data-submit-form')
  $(form_id).submit()
  event.preventDefault()
)

$(document).on('turbolinks:load', ->
  # new order: once a client is selected, activate the category checkbox
  cwi = $('#client_work_item_id')
  if cwi.length > 0 && cwi[0].selectize
    cwi[0].selectize.on('change', (element) ->
      $('#category_active').prop('disabled', false)
      categoryParam = 'work_item[parent_id]=' + element
      $('#category_work_item_id_create_link').
        attr('data-params', categoryParam).
        data('params', categoryParam)
    )

  $('#target_scope_icon').selectize({ render: { option: renderIconItem, item: renderIconItem } })
  $('#order_status_style').selectize({ render: { option: renderStyleItem, item: renderStyleItem } })
)