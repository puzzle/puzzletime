//  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
//  PuzzleTime and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/puzzle/puzzletime.


const app = window.App || (window.App = {});

const prepareModalRequest = function(event, xhr, settings) {
  const index = settings.url.indexOf('?');
  if (index < 1) {
    return settings.url += '.js';
  } else {
    return settings.url = settings.url.substr(0, index) + '.js' + settings.url.substr(index);
  }
};

const showModal = function(event, data, status, xhr) {
  const $this = $(this);
  const modal = $($this.data('modal'));
  modal.find('.modal-body').html(data);
  const title = $this.data('title');
  if (title) {
    modal.find('.modal-title').html(title);
  }
  modal.data('originator', $this);
  return modal.modal('show');
};

const processCreatedEntry = function(event, data, status, xhr) {
  data = $.parseJSON(eval(data));
  const modal = $(this).closest('.modal');
  const originator = modal.data('originator');
  if (originator.data('update') === 'selectize') {
    addOptionToSelectize(originator, data);
  } else if (originator.data('update') === 'element') {
    replaceElementModalContent(originator, data);
  }
  return modal.modal('hide');
};

var addOptionToSelectize = function(originator, data) {
  const {
    selectize
  } = $(originator.data('element'))[0];
  const idField = originator.data('idField');
  const id = idField ? data[idField] : data.id;
  selectize.addOption({ value: id, text: data.label });
  selectize.refreshOptions(false);
  return selectize.addItem(id);
};

var replaceElementModalContent = function(originator, data) {
  const element = $(originator.data('element'));
  const contentField = originator.data('contentField');
  const content = contentField ? data[contentField] : data.content;
  return element.html(content);
};

const displayFormWithErrors = function(event, xhr, status, error) {
  const $this = $(this);
  $this.closest('.modal-body').html(xhr.responseText);
  return event.stopPropagation();
};



//###############################################################
// because of turbolinks.jquery, do bind ALL document events here

// wire up modal links
$(document).on('ajax:beforeSend', '[data-modal]', prepareModalRequest);
$(document).on('ajax:success', '[data-modal]', showModal);

// wire up forms in modal dialogs
$(document).on('ajax:success', '.modal form', processCreatedEntry);
$(document).on('ajax:error', '.modal form', displayFormWithErrors);

// wire up cancel links in modal dialogs
$(document).on('click', '.modal .cancel', function(event) {
  $(this).closest('.modal').modal('hide');
  return event.preventDefault();
});
