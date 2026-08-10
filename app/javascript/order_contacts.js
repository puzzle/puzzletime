//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});

app.loadContactsWithCrm = function() {
  const clientId = $('#client_work_item_id').val();

  if (clientId.length < 1) {
    $('.add_nested_fields_link[data-association-path=order_order_contacts]').addClass('disabled');
    return;
  }

  let url = $('form[data-contacts-url]').data('contacts-url');
  url = (url += '?client_work_item_id=' + clientId);

  const addButton = $('.add_nested_fields_link[data-association-path=order_order_contacts]');
  addButton.hide().siblings('.spinner').show();

  if (this.xhr) { this.xhr.abort(); }
  return this.xhr = $.getJSON(url, function(data) {
    replaceContactsWithCrm(data);
    return addButton.show().removeClass('disabled').siblings('.spinner').hide();
  });
};

var replaceContactsWithCrm = function(data) {
  const original = $('#order_order_contacts_template').html();
  if (!original) { return; } // probably page was left in the mean time
  let modified = original.replace(/<option value=".+">.*<\/option>/g, '');
  data.forEach(function(element) {
    const option = `<option value=\"${element.id_or_crm}\">${element.label}</option>`;
    return modified = modified.replace(/<\/select>/, option + '</select>');
  });

  return $('#order_order_contacts_template').html(modified);
};



//###############################################################
// because of turbolinks.jquery, do bind ALL document events here

$(document).on('change', '#new_order #client_work_item_id', app.loadContactsWithCrm);

$(document).on('turbolinks:load', function() {
  if (!$('#client_work_item_id').val()) {
    return $('.add_nested_fields_link[data-association-path=order_order_contacts]').addClass('disabled');
  }
});