import { Controller } from "@hotwired/stimulus"
import { loadWalk, saveWalk, clearWalk } from "walk_storage"

// Live walk tracking. ALL the GPS logic lives in this controller, so the position source
// (the browser today) can be replaced by a Capacitor plugin in V2 without touching the rest.
// The walk is saved in the phone after each point and sent to the server only at the end.

const SECONDS_BETWEEN_POINTS = 5
const MAX_ACCURACY_METERS = 30 // less precise positions are ignored
const MIN_MOVE_METERS = 5 // smaller moves are GPS noise while standing still
const EARTH_RADIUS_METERS = 6371000

const STATUSES = {
  searching: "🟠 Recherche du GPS…",
  good: "🟢 GPS ok",
  weak: "🟠 GPS faible",
  bad: "🔴 GPS imprécis (position ignorée)",
  lost: "🔴 GPS perdu",
  denied: "🔴 Localisation refusée : autorise-la dans le navigateur",
  unavailable: "🔴 GPS indisponible sur cet appareil",
  finished: "⏹ Balade terminée, pas encore enregistrée"
}

export default class extends Controller {
  static targets = ["status", "duration", "distance", "finishButton"]
  static values = { saveUrl: String }

  connect() {
    this.#restoreOrStart()
    this.#showDuration()
    this.#showDistance()

    if (this.endedAt) return this.#showRetry() // finished, but the last save failed

    this.timer = setInterval(() => this.#showDuration(), 1000)
    this.#watchPosition()
    this.#keepScreenOn()
  }

  // Leaving the page stops the GPS but keeps the walk in the phone, ready to resume.
  disconnect() {
    this.#stopTracking()
  }

  async finish() {
    if (!this.endedAt) {
      if (!confirm("Terminer la balade ?")) return

      this.endedAt = new Date()
      this.#stopTracking()
      this.#persist()
    }
    this.finishButtonTarget.disabled = true
    this.finishButtonTarget.textContent = "Enregistrement…"

    try {
      const response = await this.#save()
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const { url } = await response.json()
      clearWalk()
      window.location.assign(url)
    } catch {
      alert("La balade n'a pas pu être enregistrée (pas de réseau ?). Elle est gardée dans le téléphone : réessaie dans un instant.")
      this.#showRetry()
    }
  }

  #restoreOrStart() {
    const saved = loadWalk()
    if (saved) {
      this.startedAt = new Date(saved.startedAt)
      this.endedAt = saved.endedAt ? new Date(saved.endedAt) : null
      this.points = saved.points
      this.distanceMeters = saved.distanceMeters
    } else {
      this.startedAt = new Date()
      this.endedAt = null
      this.points = []
      this.distanceMeters = 0
      this.#persist()
    }
  }

  #persist() {
    saveWalk({
      startedAt: this.startedAt.toISOString(),
      endedAt: this.endedAt?.toISOString(),
      points: this.points,
      distanceMeters: this.distanceMeters
    })
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
    this.#showStatus(accuracy <= 15 ? "good" : accuracy <= MAX_ACCURACY_METERS ? "weak" : "bad")
    if (accuracy > MAX_ACCURACY_METERS) return

    const recordedAt = new Date(position.timestamp)
    const point = { latitude, longitude, accuracy, recorded_at: recordedAt.toISOString() }
    const lastPoint = this.points.at(-1)

    if (lastPoint) {
      // One point every few seconds is enough for the path, and lighter for the phone.
      if ((recordedAt - new Date(lastPoint.recorded_at)) / 1000 < SECONDS_BETWEEN_POINTS) return

      // Standing still, the GPS "wobbles" by a few meters: don't count it as walking.
      const moved = distanceBetween(lastPoint, point)
      if (moved < Math.max(accuracy, MIN_MOVE_METERS)) return

      this.distanceMeters += moved
    }
    this.points.push(point)
    this.#persist()
    this.#showDistance()
  }

  // Screen Wake Lock: the screen stays on, so the browser keeps receiving positions.
  // The phone releases it when the screen is switched off; it is asked again when coming back.
  async #keepScreenOn() {
    if (!("wakeLock" in navigator)) return

    if (!this.onVisibilityChange) {
      this.onVisibilityChange = () => {
        if (document.visibilityState === "visible" && !this.endedAt) this.#keepScreenOn()
      }
      document.addEventListener("visibilitychange", this.onVisibilityChange)
    }
    try {
      const wakeLock = await navigator.wakeLock.request("screen")
      // The walk may have been stopped while the phone was answering.
      if (this.onVisibilityChange) this.wakeLock = wakeLock
      else wakeLock.release()
    } catch {
      // Refused (battery saver…): tracking still works while the screen is on.
    }
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
    if (this.onVisibilityChange) document.removeEventListener("visibilitychange", this.onVisibilityChange)
    this.onVisibilityChange = null
    this.wakeLock?.release().catch(() => {})
    this.wakeLock = null
  }

  #showRetry() {
    this.#showStatus("finished")
    this.finishButtonTarget.disabled = false
    this.finishButtonTarget.textContent = "↻ Réessayer l'enregistrement"
  }

  #showDuration() {
    const seconds = Math.floor(((this.endedAt || new Date()) - this.startedAt) / 1000)
    const parts = [Math.floor(seconds / 3600), Math.floor(seconds / 60) % 60, seconds % 60]
    this.durationTarget.textContent = parts.map((n) => String(n).padStart(2, "0")).join(":")
  }

  #showDistance() {
    this.distanceTarget.textContent = `${(this.distanceMeters / 1000).toFixed(1).replace(".", ",")} km`
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
