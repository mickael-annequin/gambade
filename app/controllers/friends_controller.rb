# The address book of my dog: the dogs met often during walks.
class FriendsController < ApplicationController
  before_action :require_dog
  before_action :set_friend, only: %i[show edit update destroy]

  def index
    @friends = current_dog.friends.ranked
  end

  def show
    @encounters = @friend.encounters.includes(:walk).order(met_at: :desc)
  end

  def new
    @friend = current_dog.friends.new
  end

  def create
    @friend = current_dog.friends.new(friend_params)
    if @friend.save
      redirect_to @friend, notice: "#{@friend.name} est dans le carnet d'amis."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @friend.update(friend_params)
      redirect_to @friend, notice: "Fiche mise à jour."
    else
      render :edit, status: :unprocessable_content
    end
  end

  # The encounters stay (with their own name), only the link to the friend goes.
  def destroy
    @friend.destroy
    redirect_to friends_path, notice: "#{@friend.name} n'est plus dans le carnet.", status: :see_other
  end

  private

  def set_friend
    @friend = current_dog.friends.find(params[:id])
  end

  def friend_params
    params.require(:friend).permit(:name, :breed, :note)
  end
end
