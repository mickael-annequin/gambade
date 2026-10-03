class PagesController < ApplicationController
  def home
    # First visit: create the dog profile before anything else.
    redirect_to new_dog_path unless current_user.dogs.exists?
  end
end
