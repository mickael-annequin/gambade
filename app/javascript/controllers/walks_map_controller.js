import { Controller } from "@hotwired/stimulus"
import mapboxgl from "mapbox-gl"

// Color of a track piece from the number of walks that went there (same as the legend under the map).
const PASSES_COLOR = [
  "step", [ "get", "passes" ],
  "#5BA55B", // 1: green
  2, "#E8C547", // 2–3: yellow
  4, "#E08E45", // 4–6: ochre
  7, "#C8442F", // 7–10: red
  11, "#3B3127" // 11+: bark brown
]

// All the walks on one map. Each piece of track is colored by how many walks went there
// (computed by PathFrequency), so the usual paths stand out. Tapping a track shows its walk.
export default class extends Controller {
  static values = {
    apiKey: String,
    walks: Array // [{ url: "/walks/3", label: "Hier · 2,3 km", pieces: [{ passes: 2, track: [[lng, lat], ...] }] }, ...]
  }

  connect() {
    mapboxgl.accessToken = this.apiKeyValue
    this.map = new mapboxgl.Map({
      container: this.element,
      style: "mapbox://styles/mapbox/outdoors-v12",
      center: this.walksValue[0].pieces[0].track[0],
      zoom: 13
    })
    this.map.on("load", () => this.#showWalks())
  }

  // Free the map when Turbo leaves the page.
  disconnect() {
    this.map?.remove()
  }

  #showWalks() {
    const features = this.walksValue.flatMap(({ url, label, pieces }, walk) =>
      pieces.map(({ passes, track }) => ({
        type: "Feature", properties: { walk, url, label, passes },
        geometry: { type: "LineString", coordinates: track }
      }))
    )
    this.map.addSource("walks", { type: "geojson", data: { type: "FeatureCollection", features } })

    this.map.addLayer({
      id: "walks",
      type: "line",
      source: "walks",
      layout: { "line-join": "round", "line-cap": "round", "line-sort-key": [ "get", "passes" ] }, // busiest on top
      paint: { "line-color": PASSES_COLOR, "line-width": 4 }
    })
    // The tapped walk: drawn again on top, thicker, with a white outline (nothing selected at first).
    this.map.addLayer({
      id: "selected-outline",
      type: "line",
      source: "walks",
      filter: [ "==", [ "get", "walk" ], -1 ],
      layout: { "line-join": "round", "line-cap": "round" },
      paint: { "line-color": "#ffffff", "line-width": 10 }
    })
    this.map.addLayer({
      id: "selected",
      type: "line",
      source: "walks",
      filter: [ "==", [ "get", "walk" ], -1 ],
      layout: { "line-join": "round", "line-cap": "round" },
      paint: { "line-color": PASSES_COLOR, "line-width": 6 }
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

    const first = this.walksValue[0].pieces[0].track[0]
    const bounds = new mapboxgl.LngLatBounds(first, first)
    features.forEach(({ geometry }) => geometry.coordinates.forEach((point) => bounds.extend(point)))
    this.map.fitBounds(bounds, { padding: 30, maxZoom: 16, duration: 0 })
  }

  // The tapped walk stands out, with a bubble: its day, its distance and a link to the walk.
  #select(feature, lngLat) {
    const walkFilter = [ "==", [ "get", "walk" ], feature.properties.walk ]
    this.map.setFilter("selected-outline", walkFilter)
    this.map.setFilter("selected", walkFilter)

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
