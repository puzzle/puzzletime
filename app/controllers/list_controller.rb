# encoding: UTF-8

# Abstract controller providing a basic list action.
# The loaded model entries are available in the view as an instance variable
# named after the +model_class+ or by the helper method +entries+.
#
# The +index+ action lists all entries of a certain model and provides
# functionality to search and sort this list.
# Furthermore, it remembers the last search and sort parameters after the
# user returns from a displayed or edited entry.
class ListController < ApplicationController

  include DryCrud::GenericModel
  include DryCrud::Nestable
  include DryCrud::Rememberable
  include DryCrud::RenderCallbacks

  # customized cancan code to authorize with #model_class
  authorize_resource except: :index
  before_action :authorize_class, only: :index

  define_render_callbacks :index

  helper_method :entries

  ##############  ACTIONS  ############################################

  # List all entries of this model.
  #   GET /entries
  #   GET /entries.json
  def index
    entries
  end

  private

  # Helper method to access the entries to be displayed in the current index
  # page in an uniform way.
  def entries
    model_ivar_get(true) || model_ivar_set(list_entries)
  end

  # The base relation used to filter the entries.
  # Calls the #list scope if it is defined on the model class.
  #
  # This method may be adapted as long it returns an
  # <tt>ActiveRecord::Relation</tt>.
  # Some of the modules included extend this method.
  def list_entries
    entries = model_class.respond_to?(:list) ? model_scope.list : model_scope
    entries.page(params[:page])
  end

  def authorize_class
    authorize!(action_name.to_sym, model_class)
  end

  # Include these modules after the #list_entries method is defined.
  include DryCrud::Searchable
  include DryCrud::Sortable
end
