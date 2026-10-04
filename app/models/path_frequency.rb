# How many different walks went through each place, to color the global map (green = once … dark = 11+ times).
# The map is cut into small squares (~22 m). A walk counts in the squares it went through and in their
# neighbours, so two walks on the same path still meet despite the GPS imprecision (5–10 m).
class PathFrequency
  CELL_LATITUDE = 0.0002  # ~22 m
  CELL_LONGITUDE = 0.0003 # ~22 m in France

  def initialize(walks)
    @counts = Hash.new(0)
    walks.each do |walk|
      cells = walk.track_points.map { |point| cell(point.latitude, point.longitude) }.uniq
      cells.flat_map { |square| with_neighbours(square) }.uniq.each { |square| @counts[square] += 1 }
    end
  end

  # Number of walks that went through this place ([longitude, latitude], like the map tracks).
  def passes_at(coordinates)
    longitude, latitude = coordinates
    [ @counts[cell(latitude, longitude)], 1 ].max
  end

  # The track cut into pieces of the same number of passes, to color each piece:
  # [{ passes: 1, track: [[lng, lat], ...] }, { passes: 4, track: [...] }, ...]
  def pieces(track)
    pieces = []
    track.each_cons(2) do |from, to|
      passes = [ passes_at(from), passes_at(to) ].min # a piece is only as busy as its quieter end
      if pieces.last&.fetch(:passes) == passes
        pieces.last[:track] << to
      else
        pieces << { passes: passes, track: [ from, to ] }
      end
    end
    pieces
  end

  private

  def cell(latitude, longitude)
    [ (latitude.to_f / CELL_LATITUDE).floor, (longitude.to_f / CELL_LONGITUDE).floor ]
  end

  def with_neighbours((row, column))
    [ -1, 0, 1 ].product([ -1, 0, 1 ]).map { |row_step, column_step| [ row + row_step, column + column_step ] }
  end
end
