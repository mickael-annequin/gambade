class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_dog

  private

  # For now the app follows a single dog: the first one of the account.
  def current_dog
    @current_dog ||= current_user.dogs.first
  end

  def require_dog
    redirect_to new_dog_path if current_dog.nil?
  end
end
