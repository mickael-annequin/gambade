class PagesController < ApplicationController
  # First visit: create the dog profile before anything else.
  before_action :require_dog

  def home
    walks = current_dog.walks
    @week_walks = walks.where(started_at: Time.current.beginning_of_week..)
    # Cares to do in less than a week, or late (most urgent first).
    @cares_due = current_dog.latest_cares.select { |care| care.days_left && care.days_left <= CaresHelper::SOON_DAYS }
                            .sort_by(&:days_left)
    @last_walk = walks.most_recent_first.includes(:activities, :track_points).first
  end
end
