# encoding: utf-8

class ManageController < CrudController

  before_action :authorize

  def synchronize
    mapper = model_class.puzzlebase_map
    flash[:notice] = models_label(true) + ' wurden nicht aktualisiert'
    redirect_to index_url if mapper.nil?
    @errors = mapper.synchronize
    if @errors.empty?
      flash[:notice] = models_label(true) + ' wurden erfolgreich aktualisiert'
      redirect_to index_url
    else
      flash[:notice] = 'Folgende Fehler sind bei der Synchronisation aufgetreten:'
      render action: 'synchronize'
    end
  end

end
