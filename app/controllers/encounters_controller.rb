# Optional details about a dog met during a walk, filled in after the walk.
class EncountersController < ApplicationController
  before_action :require_dog
  before_action :set_encounter

  def edit
  end

  def update
    if @encounter.update(encounter_params)
      redirect_to walk_path(@walk), notice: "Rencontre mise à jour."
    else
      render :edit, status: :unprocessable_content
    end
  end

  # For a "+1 chien" pressed by mistake.
  def destroy
    @encounter.destroy
    @walk.update!(dogs_met_count: @walk.encounters.count)
    redirect_to walk_path(@walk), notice: "Rencontre supprimée.", status: :see_other
  end

  private

  def set_encounter
    @walk = current_dog.walks.find(params[:walk_id])
    @encounter = @walk.encounters.find(params[:id])
  end

  def encounter_params
    params.require(:encounter).permit(:dog_name, :breed, :mood, :note)
  end
end
