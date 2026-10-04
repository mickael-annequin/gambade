# Optional details about a dog met during a walk, filled in after the walk.
class EncountersController < ApplicationController
  before_action :require_dog
  before_action :set_encounter

  def edit
  end

  def update
    @encounter.assign_attributes(encounter_params)
    link_to_new_friend if params.dig(:encounter, :add_to_friends) == "1"
    if @encounter.save
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
    params.require(:encounter).permit(:dog_name, :breed, :mood, :note, :friend_id)
  end

  # "➕ Ajouter au carnet": the dog becomes a friend (or is linked to the friend with that name).
  def link_to_new_friend
    return if @encounter.friend || @encounter.dog_name.blank?

    @encounter.friend = current_dog.friends.named(@encounter.dog_name) ||
                        current_dog.friends.build(name: @encounter.dog_name.strip, breed: @encounter.breed)
  end
end
