if (!window.nested_form_fields) { window.nested_form_fields = {}; }

nested_form_fields.bind_nested_forms_links = function() {
  $('body').off("click", '.add_nested_fields_link');
  $('body').on('click', '.add_nested_fields_link', function(event, additional_data) {
    let $template;
    const $link = $(this);
    const object_class = $link.data('object-class');
    const association_path = $link.data('association-path');
    const added_index = $(`.nested_${association_path}`).length;
    $.event.trigger("fields_adding.nested_form_fields",{object_class, added_index, association_path, additional_data});
    if ($link.data('scope')) {
      $template = $(`${$link.data('scope')} #${association_path}_template`);
    } else {
      $template = $(`#${association_path}_template`);
    }
    const target = $link.data('insert-into');

    let template_html = $template.html();

    // insert association indexes
    const index_placeholder = `__${association_path}_index__`;
    template_html = template_html.replace(new RegExp(index_placeholder,"g"), added_index);
	// look for replacements in user defined code and substitute with the index
    template_html = template_html.replace(new RegExp("__nested_field_for_replace_with_index__","g"), added_index);

    // replace child template div tags with script tags to avoid form submission of templates
    const $parsed_template = $(template_html);
    const $child_templates = $parsed_template.closestChild('.form_template');
    $child_templates.each(function() {
      const $child = $(this);
      return $child.replaceWith($(`<script id='${$child.attr('id')}' type='text/html' />`).html($child.html()));
    });

    if (target != null) {
      $('#' + target).append($parsed_template);
    } else {
      $template.before( $parsed_template );
    }
    $parsed_template.trigger("fields_added.nested_form_fields", {object_class, added_index, association_path, event, additional_data});
    return false;
  });

  $('body').off("click", '.remove_nested_fields_link');
  return $('body').on('click', '.remove_nested_fields_link', function() {
    const $link = $(this);
    if (($.rails !== undefined) && !$.rails.allowAction($link)) { return false; }
    if ($link.attr('disabled')) { return false; }
    const object_class = $link.data('object-class');
    const delete_association_field_name = $link.data('delete-association-field-name');
    const removed_index = parseInt(delete_association_field_name.match('(\\d+\\]\\[_destroy])')[0].match('\\d+')[0]);
    $.event.trigger("fields_removing.nested_form_fields",{object_class, delete_association_field_name, removed_index });
    const $nested_fields_container = $link.parents(".nested_fields").first();
    const delete_field = $nested_fields_container.find(`input[type='hidden'][name='${delete_association_field_name}']`);
    if (delete_field.length > 0) {
      delete_field.val('1');
    } else {
      $nested_fields_container.before(`<input type='hidden' name='${delete_association_field_name}' value='1' />`);
    }
    $nested_fields_container.hide();
    $nested_fields_container.find('input[required]:hidden, select[required]:hidden, textarea[required]:hidden').removeAttr('required');
    $nested_fields_container.trigger("fields_removed.nested_form_fields",{object_class, delete_association_field_name, removed_index});
    return false;
  });
};

$(document).on("page:change turbolinks:load", () => nested_form_fields.bind_nested_forms_links());

jQuery(() => nested_form_fields.bind_nested_forms_links());


//
// * jquery.closestchild 0.1.1
// *
// * Author: Andrey Mikhaylov aka lolmaus
// * Email: lolmaus@gmail.com
// *
//

$.fn.closestChild = function(selector) {
  let $children = undefined;
  let $results = undefined;
  $children = this.children();
  if ($children.length === 0) { return $(); }
  $results = $children.filter(selector);
  if ($results.length > 0) {
    return $results;
  } else {
    return $children.closestChild(selector);
  }
};
