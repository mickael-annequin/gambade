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
                                   points: track_points_params, encounters: encounters_params,
                                   activities: activities_params)
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

  # Each "+1 chien": when, and where if the GPS knew the position.
  def encounters_params
    encounters = params.fetch(:walk, {}).fetch(:encounters, [])
    encounters.map { |encounter| encounter.permit(:latitude, :longitude, :met_at).to_h.symbolize_keys }
              .select { |encounter| Encounter.new(encounter.merge(walk: Walk.new)).valid? }
  end

  # Play (🎾) and swim (💦) phases.
  def activities_params
    activities = params.fetch(:walk, {}).fetch(:activities, [])
    activities.map { |activity| activity.permit(:kind, :started_at, :ended_at, :latitude, :longitude).to_h.symbolize_keys }
              .select { |activity| Activity.new(activity.merge(walk: Walk.new)).valid? }
  end

  # Keeps only points with valid coordinates.
  def track_points_params
    points = params.fetch(:walk, {}).fetch(:track_points, [])
    points.map { |point| point.permit(:latitude, :longitude, :accuracy, :recorded_at).to_h.symbolize_keys }
          .select { |point| TrackPoint.new(point.merge(walk: Walk.new)).valid? }
  end
end
