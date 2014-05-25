# encoding: utf-8

class MembershipsController < ApplicationController

  # TODO move to application controller
  before_action :authenticate

  helper_method :main_path

  def show
    list
    @projects = @subject.projectmemberships.where(active: true).
                                            sort_by { |m| m.project }
  end

  def create_manager
    set_manager(true)
  end

  def destroy_manager
    set_manager(false)
  end

  def create_membership
    if params.key?(:ids)
      params[:ids].each do |id|
        config = activate_config(id)
        Projectmembership.activate(config)
      end
      flash[:notice] = 'Der/Die Mitarbeiter wurden dem Projekt hinzugefügt'
    else
      flash[:notice] = 'Bitte wählen sie einen oder mehrere Mitarbeiter'
    end
    redirect_to_list
  end

  def destroy_membership
    Projectmembership.deactivate(params[:id])
    flash[:notice] = 'Der Mitarbeiter wurde vom Projekt entfernt'
    redirect_to_list
  end

  private

  def main_path
  end

  def redirect_to_list
    redirect_to main_path
  end

  def set_manager(bool)
    projectmembership = Projectmembership.find(params[:id])
    projectmembership.update_attributes!(projectmanagement: bool)
    # reload list for user (old version is cached otherwise)
    @user.managed_projects(true) if projectmembership.employee_id == @user.id
    flash[:notice] = "#{projectmembership.employee} wurde als Projektleiter #{bool ? 'erfasst' : 'entfernt'}"
    redirect_to_list
  end

end
