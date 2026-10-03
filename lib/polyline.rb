# Encodes GPS coordinates in the "encoded polyline" format (Google, also used by Mapbox),
# a short text that fits in a URL: [[-120.2, 38.5], [-120.95, 40.7]] -> "_p~iF~ps|U_ulLnnqC".
# https://developers.google.com/maps/documentation/utilities/polylinealgorithm
module Polyline
  # coordinates: [[longitude, latitude], ...]
  def self.encode(coordinates)
    previous = [ 0, 0 ]
    coordinates.map do |longitude, latitude|
      current = [ (latitude * 1e5).round, (longitude * 1e5).round ]
      chunk = current.zip(previous).map { |value, before| encode_number(value - before) }.join
      previous = current
      chunk
    end.join
  end

  # Each number is cut into 5-bit pieces, each turned into a printable character.
  def self.encode_number(number)
    number = number.negative? ? ~(number << 1) : (number << 1)
    text = +""
    while number >= 0x20
      text << ((0x20 | (number & 0x1f)) + 63).chr
      number >>= 5
    end
    text << (number + 63).chr
  end
end
