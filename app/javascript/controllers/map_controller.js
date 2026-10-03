import { Controller } from "@hotwired/stimulus"
import mapboxgl from "mapbox-gl"

// Displays a Mapbox map centered on a point.
export default class extends Controller {
  static values = { apiKey: String, center: Array, zoom: { type: Number, default: 13 } }

  connect() {
    mapboxgl.accessToken = this.apiKeyValue
    this.map = new mapboxgl.Map({
      container: this.element,
      style: "mapbox://styles/mapbox/outdoors-v12",
      center: this.centerValue,
      zoom: this.zoomValue
    })
  }

  // Free the map when Turbo leaves the page.
  disconnect() {
    this.map?.remove()
  }
}
