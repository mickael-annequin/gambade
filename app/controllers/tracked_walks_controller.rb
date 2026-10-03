# Walks recorded live with the phone's GPS.
# "new" shows the "Balade en cours" screen; the tracking itself happens in the browser
# (Stimulus "tracking" controller), which sends the whole walk to "create" when it ends.
class TrackedWalksController < ApplicationController
  before_action :require_dog

  def new
  end

  def create
    started_at = parse_time(walk_params[:started_at])
    ended_at = parse_time(walk_params[:ended_at])
    return render_error if started_at.nil? || ended_at.nil?

    walk = Walk.create_from_track!(dog: current_dog, started_at: started_at, ended_at: ended_at,
                                   points: track_points_params)
    render json: { url: walk_path(walk) }, status: :created
  rescue ActiveRecord::RecordInvalid
    render_error
  end

  private

  def parse_time(value)
    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def render_error
    render json: { error: "La balade n'a pas pu être enregistrée." }, status: :unprocessable_content
  end

  def walk_params
    params.require(:walk).permit(:started_at, :ended_at)
  end

  # Keeps only points with valid coordinates.
  def track_points_params
    points = params.fetch(:walk, {}).fetch(:track_points, [])
    points.map { |point| point.permit(:latitude, :longitude, :accuracy, :recorded_at).to_h.symbolize_keys }
          .select { |point| TrackPoint.new(point.merge(walk: Walk.new)).valid? }
  end
end
