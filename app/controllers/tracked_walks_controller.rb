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

    # Already received (the phone did not get the answer and sent it again): don't save it twice.
    existing_walk = find_already_saved_walk
    return render json: { url: walk_path(existing_walk, finished: true) } if existing_walk

    walk = Walk.create_from_track!(dog: current_dog, started_at: started_at, ended_at: ended_at,
                                   points: track_points_params, encounters: encounters_params,
                                   activities: activities_params, client_id: walk_params[:client_id].presence)
    WalkWeatherJob.perform_later(walk)
    render json: { url: walk_path(walk, finished: true) }, status: :created
  rescue ActiveRecord::RecordNotUnique
    # Both sendings arrived at the same moment: the other one won.
    render json: { url: walk_path(find_already_saved_walk, finished: true) }
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
    params.require(:walk).permit(:started_at, :ended_at, :client_id)
  end

  def find_already_saved_walk
    client_id = walk_params[:client_id].presence
    client_id && current_dog.walks.find_by(client_id: client_id)
  end

  # Each "+1 chien": when, where if the GPS knew the position, and maybe the name and mood given during the walk.
  def encounters_params
    encounters = params.fetch(:walk, {}).fetch(:encounters, [])
    encounters.map { |encounter| encounter.permit(:latitude, :longitude, :met_at, :dog_name, :mood).to_h.symbolize_keys }
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
