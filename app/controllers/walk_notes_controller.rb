# Notes about a walk: how the dog was (several moods) and a free comment.
class WalkNotesController < ApplicationController
  before_action :require_dog
  before_action :set_walk

  def edit
  end

  def update
    if @walk.update(notes_params)
      redirect_to walk_path(@walk), notice: "Notes enregistrées."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_walk
    @walk = current_dog.walks.find(params[:walk_id])
  end

  # The mood checkboxes also send an empty value (so that unchecking everything works): it is removed.
  def notes_params
    notes = params.require(:walk).permit(:comment, moods: [])
    notes[:moods] = notes[:moods].to_a.compact_blank
    notes
  end
end
