class WalksController < ApplicationController
  before_action :set_dog
  before_action :set_walk, only: %i[show edit update destroy]

  def index
    @walks = @dog.walks.most_recent_first
  end

  def show
  end

  def new
    @walk = @dog.walks.new(started_at: Time.current.change(sec: 0))
  end

  def create
    @walk = @dog.walks.new(walk_params)
    if @walk.save
      redirect_to @walk, notice: "Balade enregistrée."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @walk.update(walk_params)
      redirect_to @walk, notice: "Balade mise à jour."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @walk.destroy
    redirect_to walks_path, notice: "Balade supprimée.", status: :see_other
  end

  private

  def set_dog
    @dog = current_user.dogs.first
    redirect_to new_dog_path if @dog.nil?
  end

  # Only look among my dog's walks, so nobody can open another account's walk by changing the id in the URL.
  def set_walk
    @walk = @dog.walks.find(params[:id])
  end

  def walk_params
    params.require(:walk).permit(:started_at, :duration_minutes, :distance_km, :dogs_met_count)
  end
end
