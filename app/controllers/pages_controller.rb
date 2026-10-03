class PagesController < ApplicationController
  # First visit: create the dog profile before anything else.
  before_action :require_dog

  def home
  end
end
