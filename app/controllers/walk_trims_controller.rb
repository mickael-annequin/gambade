# "Couper la fin" of a tracked walk, when "Terminer" was forgotten.
class WalkTrimsController < ApplicationController
  before_action :require_dog
  before_action :set_walk

  def edit
    @progress = @walk.track_progress
    redirect_to @walk, alert: "Cette balade n'a pas de trajet GPS à couper." if @progress.size < 2
  end

  def update
    ended_at = Time.zone.parse(params[:ended_at].to_s)
    if ended_at.nil? || ended_at <= @walk.started_at
      redirect_to edit_walk_trim_path(@walk), alert: "Choisis un moment de la balade."
    else
      @walk.trim_end!(ended_at)
      redirect_to @walk, notice: "La fin de la balade a été coupée."
    end
  rescue ArgumentError
    redirect_to edit_walk_trim_path(@walk), alert: "Choisis un moment de la balade."
  end

  private

  def set_walk
    @walk = current_dog.walks.find(params[:walk_id])
  end
end
