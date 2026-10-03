class DogsController < ApplicationController
  before_action :set_dog, only: %i[show edit update]
  before_action :redirect_if_dog_exists, only: %i[new create]

  def show
  end

  def new
    @dog = current_user.dogs.new
  end

  def create
    @dog = current_user.dogs.new(dog_params)
    if @dog.save
      redirect_to root_path, notice: "Le profil de #{@dog.name} est créé."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @dog.update(dog_params)
      redirect_to dog_path, notice: "Profil mis à jour."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_dog
    @dog = current_dog
    redirect_to new_dog_path if @dog.nil?
  end

  def redirect_if_dog_exists
    redirect_to dog_path if current_dog
  end

  def dog_params
    params.require(:dog).permit(:name, :breed, :birth_date, :photo)
  end
end
