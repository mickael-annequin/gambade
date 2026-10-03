import { Controller } from "@hotwired/stimulus"
import mapboxgl from "mapbox-gl"

const TRACK_COLOR = "#E08E45" // ocre (docs/conception/identite.md)
const START_COLOR = "#2F5D50" // vert forêt
const END_COLOR = "#3B3127" // brun écorce
const ENCOUNTER_COLOR = "#E08E45" // ocre, the "+1 chien" color

// Displays a Mapbox map, with the walk's GPS track when there is one.
export default class extends Controller {
  static values = {
    apiKey: String,
    center: Array,
    zoom: { type: Number, default: 13 },
    track: { type: Array, default: [] }, // [[longitude, latitude], ...]
    encounters: { type: Array, default: [] } // [{ label: "1–3", times: ["18h12", …], coordinates: [lng, lat] }, ...]
  }

  connect() {
    mapboxgl.accessToken = this.apiKeyValue
    this.map = new mapboxgl.Map({
      container: this.element,
      style: "mapbox://styles/mapbox/outdoors-v12",
      center: this.centerValue,
      zoom: this.zoomValue
    })
    if (this.trackValue.length > 0) this.map.on("load", () => this.#showTrack())
  }

  // Free the map when Turbo leaves the page.
  disconnect() {
    this.map?.remove()
  }

  // A numbered marker ("1", or "1–3" for several dogs met at the same place).
  // Tapping it shows the times of the encounters.
  #addEncounterMarker({ label, times, coordinates }) {
    const element = document.createElement("div")
    element.textContent = label
    Object.assign(element.style, {
      minWidth: "26px", height: "26px", padding: "0 6px", boxSizing: "border-box",
      borderRadius: "13px", border: "2px solid white", cursor: "pointer",
      background: ENCOUNTER_COLOR, color: END_COLOR, font: "bold 14px sans-serif",
      display: "flex", alignItems: "center", justifyContent: "center"
    })
    const dogs = times.length > 1 ? `${times.length} chiens` : "1 chien"
    const popup = new mapboxgl.Popup({ offset: 16 }).setText(`🐕 ${dogs} · ${times.join(", ")}`)
    new mapboxgl.Marker({ element }).setLngLat(coordinates).setPopup(popup).addTo(this.map)
  }

  #showTrack() {
    this.map.addSource("track", {
      type: "geojson",
      data: { type: "Feature", geometry: { type: "LineString", coordinates: this.trackValue } }
    })
    this.map.addLayer({
      id: "track",
      type: "line",
      source: "track",
      layout: { "line-join": "round", "line-cap": "round" },
      paint: { "line-color": TRACK_COLOR, "line-width": 5 }
    })

    new mapboxgl.Marker({ color: START_COLOR }).setLngLat(this.trackValue[0]).addTo(this.map)
    new mapboxgl.Marker({ color: END_COLOR }).setLngLat(this.trackValue.at(-1)).addTo(this.map)
    this.encountersValue.forEach((encounter) => this.#addEncounterMarker(encounter))

    // Zoom so that the whole walk fits in the map.
    const bounds = new mapboxgl.LngLatBounds(this.trackValue[0], this.trackValue[0])
    this.trackValue.forEach((point) => bounds.extend(point))
    this.map.fitBounds(bounds, { padding: 40, maxZoom: 17, duration: 0 })
  }
}
