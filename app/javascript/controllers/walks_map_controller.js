import { Controller } from "@hotwired/stimulus"
import mapboxgl from "mapbox-gl"

const TRACK_COLOR = "#E08E45" // ocre, like the track of one walk (map_controller.js)
const SELECTED_COLOR = "#2F5D50" // vert forêt

// All the walks on one map. The tracks are see-through: where they overlap
// (the usual paths), the color gets stronger. Tapping a track shows its walk.
export default class extends Controller {
  static values = {
    apiKey: String,
    walks: Array // [{ url: "/walks/3", label: "Hier · 2,3 km", track: [[lng, lat], ...] }, ...]
  }

  connect() {
    mapboxgl.accessToken = this.apiKeyValue
    this.map = new mapboxgl.Map({
      container: this.element,
      style: "mapbox://styles/mapbox/outdoors-v12",
      center: this.walksValue[0].track[0],
      zoom: 13
    })
    this.map.on("load", () => this.#showWalks())
  }

  // Free the map when Turbo leaves the page.
  disconnect() {
    this.map?.remove()
  }

  #showWalks() {
    this.map.addSource("walks", {
      type: "geojson",
      data: {
        type: "FeatureCollection",
        features: this.walksValue.map(({ url, label, track }, index) => ({
          type: "Feature", id: index, properties: { url, label },
          geometry: { type: "LineString", coordinates: track }
        }))
      }
    })
    this.map.addLayer({
      id: "walks",
      type: "line",
      source: "walks",
      layout: { "line-join": "round", "line-cap": "round" },
      paint: {
        "line-color": [ "case", [ "boolean", [ "feature-state", "selected" ], false ], SELECTED_COLOR, TRACK_COLOR ],
        "line-width": 4,
        "line-opacity": 0.55
      }
    })
    // An invisible wide line on top, so a track is easy to tap with a finger.
    this.map.addLayer({
      id: "walks-touch",
      type: "line",
      source: "walks",
      paint: { "line-color": "#000000", "line-width": 24, "line-opacity": 0 }
    })
    this.map.on("click", "walks-touch", (event) => this.#select(event.features[0], event.lngLat))
    this.map.on("mouseenter", "walks-touch", () => { this.map.getCanvas().style.cursor = "pointer" })
    this.map.on("mouseleave", "walks-touch", () => { this.map.getCanvas().style.cursor = "" })

    const bounds = new mapboxgl.LngLatBounds(this.walksValue[0].track[0], this.walksValue[0].track[0])
    this.walksValue.forEach(({ track }) => track.forEach((point) => bounds.extend(point)))
    this.map.fitBounds(bounds, { padding: 30, maxZoom: 16, duration: 0 })
  }

  // The tapped track turns green, with a bubble: its day, its distance and a link to the walk.
  #select(feature, lngLat) {
    if (this.selectedId !== undefined) this.map.setFeatureState({ source: "walks", id: this.selectedId }, { selected: false })
    this.selectedId = feature.id
    this.map.setFeatureState({ source: "walks", id: feature.id }, { selected: true })

    const content = document.createElement("div")
    const label = document.createElement("strong")
    label.textContent = feature.properties.label
    const link = document.createElement("a")
    link.href = feature.properties.url
    link.textContent = "Voir la balade ›"
    link.style.display = "block"
    content.append(label, link)

    this.popup?.remove()
    this.popup = new mapboxgl.Popup({ offset: 8 }).setLngLat(lngLat).setDOMContent(content).addTo(this.map)
  }
}
