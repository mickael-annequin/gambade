# Stats per week or per month, with charts (/stats?period=month).
class StatsController < ApplicationController
  before_action :require_dog

  def show
    @stats = WalkStats.new(current_dog.walks, period: params[:period])
  end
end
