# Deletes a play (🎾) or swim (💦) phase started by mistake (e.g. a press with the phone in a pocket).
class ActivitiesController < ApplicationController
  before_action :require_dog

  def destroy
    walk = current_dog.walks.find(params[:walk_id])
    walk.activities.find(params[:id]).destroy
    redirect_to walk_path(walk), notice: "Phase supprimée.", status: :see_other
  end
end
