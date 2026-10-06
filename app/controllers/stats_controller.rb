# Stats per day, week or month, with charts (/stats?period=day).
class StatsController < ApplicationController
  before_action :require_dog

  def show
    @stats = WalkStats.new(current_dog.walks, period: params[:period])
  end
end
