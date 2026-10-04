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
    encounters: { type: Array, default: [] }, // [{ label: "1–3", times: ["18h12", …], coordinates: [lng, lat] }, ...]
    activities: { type: Array, default: [] }, // [{ icon: "🎾", times: "18h10–18h22", coordinates: [lng, lat] }, ...]
    photos: { type: Array, default: [] } // [{ id: 12, thumbnail: url, coordinates: [lng, lat] }, ...]
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

  // Shows (or moves) the ✂️ marker where the walk will be cut ("trim:moved" event).
  showCut({ detail: { coordinates } }) {
    if (!this.cutMarker) {
      const element = document.createElement("div")
      element.textContent = "✂️"
      element.style.fontSize = "26px"
      this.cutMarker = new mapboxgl.Marker({ element }).setLngLat(coordinates).addTo(this.map)
    }
    this.cutMarker.setLngLat(coordinates)
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

  // 🎾 or 💦 where a play or swim phase started; tapping it shows when.
  #addActivityMarker({ icon, times, coordinates }) {
    const element = document.createElement("div")
    element.textContent = icon
    Object.assign(element.style, { fontSize: "22px", cursor: "pointer" })
    const popup = new mapboxgl.Popup({ offset: 16 }).setText(`${icon} ${times}`)
    new mapboxgl.Marker({ element }).setLngLat(coordinates).setPopup(popup).addTo(this.map)
  }

  // A round thumbnail of the photo where it was taken; tapping it opens the photo viewer ("map:photo" event).
  #addPhotoMarker({ id, thumbnail, coordinates }) {
    const element = document.createElement("img")
    element.src = thumbnail
    element.alt = "Photo"
    Object.assign(element.style, {
      width: "40px", height: "40px", borderRadius: "50%", objectFit: "cover",
      border: "2px solid white", boxShadow: "0 1px 4px rgba(0, 0, 0, 0.35)", cursor: "pointer"
    })
    element.addEventListener("click", () => this.dispatch("photo", { detail: { id } }))
    new mapboxgl.Marker({ element }).setLngLat(coordinates).addTo(this.map)
  }

  // Small ochre arrows repeated along the track, pointing the way we walked (which way round the loop).
  // Mapbox turns each one in the direction of the line; the arrow is drawn pointing right.
  #showDirectionArrows() {
    const size = 40 // drawn at double size, shown at 20 px (sharp on phone screens)
    const canvas = document.createElement("canvas")
    canvas.width = canvas.height = size
    const context = canvas.getContext("2d")
    context.lineCap = context.lineJoin = "round"
    context.beginPath()
    context.moveTo(14, 10)
    context.lineTo(26, 20)
    context.lineTo(14, 30)
    context.strokeStyle = TRACK_COLOR // same color as the track: the arrow sticks out of the line on both sides
    context.lineWidth = 6
    context.stroke()
    this.map.addImage("direction-arrow", context.getImageData(0, 0, size, size), { pixelRatio: 2 })

    this.map.addLayer({
      id: "track-arrows",
      type: "symbol",
      source: "track",
      layout: {
        "symbol-placement": "line",
        "symbol-spacing": 90, // pixels between two arrows, whatever the zoom
        "icon-image": "direction-arrow",
        "icon-size": 1.2, // 20 px → 24 px
        "icon-allow-overlap": true
      }
    })
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

    this.#showDirectionArrows()

    new mapboxgl.Marker({ color: START_COLOR }).setLngLat(this.trackValue[0]).addTo(this.map)
    new mapboxgl.Marker({ color: END_COLOR }).setLngLat(this.trackValue.at(-1)).addTo(this.map)
    this.encountersValue.forEach((encounter) => this.#addEncounterMarker(encounter))
    this.activitiesValue.forEach((activity) => this.#addActivityMarker(activity))
    this.photosValue.forEach((photo) => this.#addPhotoMarker(photo))

    // Zoom so that the whole walk, every dog met, every play/swim phase and every photo fit in the map.
    const bounds = new mapboxgl.LngLatBounds(this.trackValue[0], this.trackValue[0])
    this.trackValue.forEach((point) => bounds.extend(point))
    this.encountersValue.forEach(({ coordinates }) => bounds.extend(coordinates))
    this.activitiesValue.forEach(({ coordinates }) => bounds.extend(coordinates))
    this.photosValue.forEach(({ coordinates }) => bounds.extend(coordinates))
    this.map.fitBounds(bounds, { padding: 40, maxZoom: 17, duration: 0 })
  }
}
