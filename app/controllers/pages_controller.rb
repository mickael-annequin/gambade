class PagesController < ApplicationController
  # First visit: create the dog profile before anything else.
  before_action :require_dog

  def home
    walks = current_dog.walks
    @week_walks = walks.where(started_at: Time.current.beginning_of_week..)
    @last_walk = walks.most_recent_first.includes(:activities, :track_points).first
  end
end
