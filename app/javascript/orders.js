//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const renderIconItem = (item, escape) => '<div><span class="glyphicon glyphicon-' + item.value + '"></span> ' + escape(item.value) + '</div>';

const renderStyleItem = (item, escape) => '<div><span class="label label-' + item.value + '">' + escape(item.value) + '</span></div>';



//###############################################################
// because of turbolinks.jquery, do bind ALL document events here

$(document).on('click', '[data-submit-form]', function(event) {
  const form_id = $(this).attr('data-submit-form');
  $(form_id).submit();
  return event.preventDefault();
});

$(document).on('turbolinks:load', function() {
  // new order: once a client is selected, activate the category checkbox
  const cwi = $('#client_work_item_id');
  if ((cwi.length > 0) && cwi[0].selectize) {
    cwi[0].selectize.on('change', function(element) {
      $('#category_active').prop('disabled', false);
      const categoryParam = 'work_item[parent_id]=' + element;
      return $('#category_work_item_id_create_link').
        attr('data-params', categoryParam).
        data('params', categoryParam);
    });
  }

  $('#target_scope_icon').selectize({ render: { option: renderIconItem, item: renderIconItem } });
  return $('#order_status_style').selectize({ render: { option: renderStyleItem, item: renderStyleItem } });
});