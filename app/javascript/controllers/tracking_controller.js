import { Controller } from "@hotwired/stimulus"

// Live walk tracking. ALL the GPS logic lives in this controller, so the position source
// (the browser today) can be replaced by a Capacitor plugin in V2 without touching the rest.
// The walk stays in the phone during the walk and is sent to the server only at the end.

const SECONDS_BETWEEN_POINTS = 5
const EARTH_RADIUS_METERS = 6371000

const STATUSES = {
  searching: "🟠 Recherche du GPS…",
  good: "🟢 GPS ok",
  weak: "🟠 GPS faible",
  bad: "🔴 GPS imprécis",
  lost: "🔴 GPS perdu",
  denied: "🔴 Localisation refusée : autorise-la dans le navigateur",
  unavailable: "🔴 GPS indisponible sur cet appareil"
}

export default class extends Controller {
  static targets = ["status", "duration", "distance", "finishButton"]
  static values = { saveUrl: String }

  connect() {
    this.startedAt = new Date()
    this.points = []
    this.distanceMeters = 0
    this.timer = setInterval(() => this.#showDuration(), 1000)
    this.#watchPosition()
  }

  disconnect() {
    this.#stopTracking()
  }

  async finish() {
    if (!this.endedAt) {
      if (!confirm("Terminer la balade ?")) return

      this.endedAt = new Date()
      this.#stopTracking()
    }
    this.finishButtonTarget.disabled = true
    this.finishButtonTarget.textContent = "Enregistrement…"

    try {
      const response = await this.#save()
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const { url } = await response.json()
      window.location.assign(url)
    } catch {
      // Nothing is lost: the walk is still in memory and can be sent again.
      alert("La balade n'a pas pu être enregistrée (pas de réseau ?). Réessaie dans un instant.")
      this.finishButtonTarget.disabled = false
      this.finishButtonTarget.textContent = "↻ Réessayer l'enregistrement"
    }
  }

  #watchPosition() {
    if (!("geolocation" in navigator)) return this.#showStatus("unavailable")

    this.#showStatus("searching")
    this.watchId = navigator.geolocation.watchPosition(
      (position) => this.#addPosition(position),
      (error) => this.#showStatus(error.code === error.PERMISSION_DENIED ? "denied" : "lost"),
      { enableHighAccuracy: true, maximumAge: 0, timeout: 20000 }
    )
  }

  #addPosition(position) {
    const { latitude, longitude, accuracy } = position.coords
    this.#showStatus(accuracy <= 20 ? "good" : accuracy <= 50 ? "weak" : "bad")

    // Keep one point every few seconds: enough for the path, light for the phone.
    const lastPoint = this.points.at(-1)
    const recordedAt = new Date(position.timestamp)
    if (lastPoint && (recordedAt - new Date(lastPoint.recorded_at)) / 1000 < SECONDS_BETWEEN_POINTS) return

    const point = { latitude, longitude, accuracy, recorded_at: recordedAt.toISOString() }
    if (lastPoint) this.distanceMeters += distanceBetween(lastPoint, point)
    this.points.push(point)
    this.distanceTarget.textContent = `${(this.distanceMeters / 1000).toFixed(1).replace(".", ",")} km`
  }

  #save() {
    return fetch(this.saveUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: JSON.stringify({
        walk: {
          started_at: this.startedAt.toISOString(),
          ended_at: this.endedAt.toISOString(),
          track_points: this.points
        }
      })
    })
  }

  #stopTracking() {
    clearInterval(this.timer)
    if (this.watchId !== undefined) navigator.geolocation.clearWatch(this.watchId)
  }

  #showDuration() {
    const seconds = Math.floor((new Date() - this.startedAt) / 1000)
    const parts = [Math.floor(seconds / 3600), Math.floor(seconds / 60) % 60, seconds % 60]
    this.durationTarget.textContent = parts.map((n) => String(n).padStart(2, "0")).join(":")
  }

  #showStatus(status) {
    this.statusTarget.textContent = STATUSES[status]
  }
}

// Distance "as the crow flies" between two GPS points, in meters (haversine formula).
function distanceBetween(from, to) {
  const toRadians = (degrees) => degrees * Math.PI / 180
  const deltaLat = toRadians(to.latitude - from.latitude)
  const deltaLng = toRadians(to.longitude - from.longitude)
  const a = Math.sin(deltaLat / 2) ** 2 +
    Math.cos(toRadians(from.latitude)) * Math.cos(toRadians(to.latitude)) * Math.sin(deltaLng / 2) ** 2
  return 2 * EARTH_RADIUS_METERS * Math.asin(Math.sqrt(a))
}
