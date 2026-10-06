import { Controller } from "@hotwired/stimulus"
import { loadWalk, saveWalk, clearWalk } from "walk_storage"

// Live walk tracking. ALL the GPS logic lives in this controller. The position source is the browser,
// or a Capacitor plugin in the Android app (V2) to keep tracking in the background.
// The walk is saved in the phone after each point and sent to the server only at the end.

const SECONDS_BETWEEN_POINTS = 5
const MAX_ACCURACY_METERS = 30 // less precise positions are ignored
const MIN_MOVE_METERS = 5 // smaller moves are GPS noise while standing still
const MAX_POSITION_AGE_SECONDS = 60 // max gap between a dog met and the position used to place it
const CAR_SPEED_KMH = 30 // faster than this is not walking: these positions are not counted
const CAR_SECONDS = 60 // fast for this long: "in the car?" question
const LEFT_START_METERS = 300 // farther than this from the start: the walk has really left
const BACK_TO_START_METERS = 50 // closer than this after having left: "back to start?" question
const MIN_WALK_METERS_BEFORE_BACK = 1000
const EARTH_RADIUS_METERS = 6371000

const ACTIVITIES = {
  play: { icon: "🎾", label: "🎾 JEU" },
  swim: { icon: "💦", label: "💦 BAIGNADE" }
}

const STATUSES = {
  searching: "🟠 Recherche du GPS…",
  good: "🟢 GPS ok",
  weak: "🟠 GPS faible",
  bad: "🔴 GPS imprécis (position ignorée)",
  lost: "🔴 GPS perdu",
  denied: "🔴 Localisation refusée : autorise-la dans les réglages",
  unavailable: "🔴 GPS indisponible sur cet appareil",
  finished: "⏹ Balade terminée, pas encore enregistrée"
}

export default class extends Controller {
  static targets = ["status", "duration", "distance", "finishButton", "dogsCount", "suggestion", "suggestionMessage",
    "playButton", "swimButton", "dogPanel", "dogPanelTitle", "dogName", "moodButton"]
  static values = { saveUrl: String }

  connect() {
    this.#restoreOrStart()
    this.#showDuration()
    this.#showDistance()
    this.#showDogsCount()
    this.#showActivities()

    if (this.endedAt) return this.#showRetry() // finished, but the last save failed

    this.timer = setInterval(() => {
      this.#showDuration()
      this.#showActivities()
    }, 1000)
    this.#watchPosition()
    this.#keepScreenOn()
  }

  // Leaving the page stops the GPS but keeps the walk in the phone, ready to resume.
  disconnect() {
    this.#stopTracking()
  }

  // "+1 chien" opens a panel; the dog is counted only with "✓ OK" (2 presses), so a press made
  // by the phone in a pocket does not count a dog. When and where are taken at the first press.
  // Without a recent position yet, the dog will be placed at the next position (#locateWaitingEncounters).
  addDog() {
    if (this.endedAt || this.pendingEncounter) return // panel already open: ignore (pocket presses)

    this.pendingEncounter = { met_at: new Date().toISOString(), ...this.#recentPosition() }
    navigator.vibrate?.(60)
    this.#openDogPanel()
  }

  // 😄 🙂 😐 😠 (data-tracking-mood-param); pressing the chosen one again unselects it.
  chooseMood({ params: { mood } }) {
    this.dogMood = this.dogMood === mood ? null : mood
    this.#showMoods()
  }

  // "✓ OK": the dog is counted, with its name and mood if they were given.
  confirmDog() {
    if (!this.pendingEncounter) return

    this.encounters.push({
      ...this.pendingEncounter,
      dog_name: this.dogNameTarget.value.trim() || undefined,
      mood: this.dogMood || undefined
    })
    this.#persist()
    this.#showDogsCount()
    navigator.vibrate?.(60)
    this.#hideDogPanel()
  }

  // "Annuler": the press on "+1 chien" was a mistake, nothing is counted.
  cancelDog() {
    this.#hideDogPanel()
  }

  // 🎾 / 💦 buttons (data-tracking-kind-param): a first press starts the phase, the next one stops it.
  // Play and swim are independent: both can run at the same time.
  toggleActivity({ params: { kind } }) {
    if (this.endedAt) return

    const running = this.#runningActivity(kind)
    if (running) running.ended_at = new Date().toISOString()
    else this.activities.push({ kind, started_at: new Date().toISOString(), ...this.#recentPosition() })
    this.#persist()
    this.#showActivities()
    navigator.vibrate?.(60)
  }

  // From the banner, the question was already asked: no confirmation (data-tracking-confirm-param="false").
  async finish({ params } = {}) {
    if (!this.endedAt) {
      if (params?.confirm !== false && !confirm("Terminer la balade ?")) return

      this.#end()
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

  // "Continuer" on the banner.
  keepWalking() {
    this.suggestedEndAt = null
    this.suggestionTarget.hidden = true
  }

  // Running phases stop with the walk. In the car, the walk really ended when the car started:
  // what came after is dropped.
  #end() {
    this.cancelDog() // a dog not confirmed with "✓ OK" is not counted
    this.endedAt = this.suggestedEndAt || new Date()
    const endedAt = this.endedAt.toISOString()
    this.points = this.points.filter((point) => new Date(point.recorded_at) <= this.endedAt)
    this.encounters = this.encounters.filter((encounter) => new Date(encounter.met_at) <= this.endedAt)
    this.activities = this.activities.filter((activity) => new Date(activity.started_at) <= this.endedAt)
    this.activities.forEach((activity) => {
      if (!activity.ended_at || new Date(activity.ended_at) > this.endedAt) activity.ended_at = endedAt
    })
    this.suggestionTarget.hidden = true
    this.#stopTracking()
    this.#persist()
    this.#showDuration()
  }

  #restoreOrStart() {
    const saved = loadWalk()
    if (saved) {
      this.startedAt = new Date(saved.startedAt)
      this.endedAt = saved.endedAt ? new Date(saved.endedAt) : null
      this.points = saved.points
      this.distanceMeters = saved.distanceMeters
      this.encounters = saved.encounters || []
      this.leftStart = saved.leftStart || false
      this.activities = saved.activities || []
      this.clientId = saved.clientId || crypto.randomUUID()
    } else {
      this.startedAt = new Date()
      this.endedAt = null
      this.points = []
      this.distanceMeters = 0
      this.encounters = []
      this.leftStart = false
      this.activities = []
      this.clientId = crypto.randomUUID() // lets the server recognize this walk if it is sent twice
      this.#persist()
    }
  }

  #persist() {
    saveWalk({
      startedAt: this.startedAt.toISOString(),
      endedAt: this.endedAt?.toISOString(),
      points: this.points,
      distanceMeters: this.distanceMeters,
      encounters: this.encounters,
      leftStart: this.leftStart,
      activities: this.activities,
      clientId: this.clientId
    })
  }

  #watchPosition() {
    if (backgroundGeolocation()) return this.#watchPositionInApp()
    if (!("geolocation" in navigator)) return this.#showStatus("unavailable")

    this.#showStatus("searching")
    this.watchId = navigator.geolocation.watchPosition(
      (position) => this.#addPosition(position),
      (error) => this.#showStatus(error.code === error.PERMISSION_DENIED ? "denied" : "lost"),
      { enableHighAccuracy: true, maximumAge: 0, timeout: 20000 }
    )
  }

  // Android app (V2): positions keep coming with the screen off or in another app (camera…),
  // while Android shows a notification. They are given the shape of a browser position,
  // so the rest of the controller works the same.
  // Location is asked first: if the plugin has to ask it itself, it doesn't show its notification
  // and Android stops the tracking in the background (first walk after installing the app).
  #watchPositionInApp() {
    this.#showStatus("searching")
    this.appWatcher = backgroundGeolocation().requestPermissions().then(({ location }) => {
      if (location !== "granted") return this.#showStatus("denied")
      if (!this.appWatcher) return // the walk was stopped while the question was asked

      return this.#addAppWatcher()
    })
  }

  // Resolves to the watcher id, needed to stop it.
  #addAppWatcher() {
    return backgroundGeolocation().addWatcher(
      {
        backgroundTitle: "Gambade 🐶",
        backgroundMessage: "Balade en cours : ton trajet est enregistré.",
        requestPermissions: true,
        stale: false, // only fresh positions
        distanceFilter: 0 // every position: #addPosition does the filtering
      },
      (location, error) => {
        if (error) return this.#showStatus(error.code === "NOT_AUTHORIZED" ? "denied" : "lost")

        const { latitude, longitude, accuracy, speed, time } = location
        this.#addPosition({ coords: { latitude, longitude, accuracy, speed }, timestamp: time })
      }
    )
  }

  #addPosition(position) {
    const { latitude, longitude, accuracy } = position.coords
    this.lastPosition = { latitude, longitude, at: new Date() }
    this.#locateWaitingEncounters()
    this.#showStatus(accuracy <= 15 ? "good" : accuracy <= MAX_ACCURACY_METERS ? "weak" : "bad")
    if (accuracy > MAX_ACCURACY_METERS) return

    const recordedAt = new Date(position.timestamp)
    if (this.#isInCar(position, recordedAt)) return

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
    this.#watchReturnToStart(point)
  }

  // Speed from the GPS when it gives it, else computed from the previous position.
  // Fast for a minute: probably in the car, "Terminer" was forgotten.
  #isInCar({ coords }, at) {
    const previous = this.previousFix
    this.previousFix = { latitude: coords.latitude, longitude: coords.longitude, at }
    let metersPerSecond = coords.speed
    if (metersPerSecond == null && previous && at > previous.at) {
      metersPerSecond = distanceBetween(previous, coords) / ((at - previous.at) / 1000)
    }
    if (metersPerSecond == null || metersPerSecond * 3.6 < CAR_SPEED_KMH) {
      this.fastSince = null
      this.askedAboutCar = false
      return false
    }

    this.fastSince ??= previous?.at || at
    if (!this.askedAboutCar && (at - this.fastSince) / 1000 >= CAR_SECONDS) {
      this.askedAboutCar = true
      this.#suggestFinish("🚗 Tu sembles être en voiture. Terminer la balade ?", this.fastSince)
    }
    return true
  }

  // Walks are usually loops: coming back near the start, after having really left, probably means the end.
  // After "Continuer", the question comes back only after leaving again (figure-8 walks).
  #watchReturnToStart(point) {
    const start = this.points[0]
    if (point === start) return

    const fromStart = distanceBetween(start, point)
    if (fromStart > LEFT_START_METERS && !this.leftStart) {
      this.leftStart = true
      this.#persist()
    } else if (this.leftStart && fromStart < BACK_TO_START_METERS && this.distanceMeters >= MIN_WALK_METERS_BEFORE_BACK) {
      this.leftStart = false
      this.#persist()
      this.#suggestFinish("🔁 Tu es revenu au point de départ. Terminer la balade ?", null)
    }
  }

  #suggestFinish(message, endAt) {
    this.suggestedEndAt = endAt
    this.suggestionMessageTarget.textContent = message
    this.suggestionTarget.hidden = false
    navigator.vibrate?.([200, 100, 200])
  }

  // { latitude, longitude } if the GPS knows where we are, else {} (placed later, see #locateWaitingEncounters).
  #recentPosition() {
    const position = this.lastPosition
    if (!position || (new Date() - position.at) / 1000 >= MAX_POSITION_AGE_SECONDS) return {}

    return { latitude: position.latitude, longitude: position.longitude }
  }

  #runningActivity(kind) {
    return this.activities.find((activity) => activity.kind === kind && !activity.ended_at)
  }

  // Gives the position just received to dogs met (and play/swim phases started) a few seconds before,
  // when the GPS had no position yet.
  #locateWaitingEncounters() {
    const { latitude, longitude, at } = this.lastPosition
    const isWaiting = (item, time) =>
      item.latitude === undefined && (at - new Date(time)) / 1000 < MAX_POSITION_AGE_SECONDS
    const waiting = [
      ...[ this.pendingEncounter, ...this.encounters ].filter((encounter) => encounter && isWaiting(encounter, encounter.met_at)),
      ...this.activities.filter((activity) => isWaiting(activity, activity.started_at))
    ]
    if (waiting.length === 0) return

    waiting.forEach((item) => Object.assign(item, { latitude, longitude }))
    this.#persist()
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
          client_id: this.clientId,
          started_at: this.startedAt.toISOString(),
          ended_at: this.endedAt.toISOString(),
          track_points: this.points,
          encounters: this.encounters,
          activities: this.activities
        }
      })
    })
  }

  #stopTracking() {
    clearInterval(this.timer)
    if (this.watchId !== undefined) navigator.geolocation.clearWatch(this.watchId)
    // The watcher id comes later (a Promise): the watcher is removed as soon as it is known.
    this.appWatcher?.then((id) => id && backgroundGeolocation().removeWatcher({ id }))
    this.appWatcher = null
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

  // "🎾 JEU", or "🎾 03:12 ■ Arrêter" while the phase is running.
  #showActivities() {
    for (const [kind, { icon, label }] of Object.entries(ACTIVITIES)) {
      const running = this.#runningActivity(kind)
      const button = this[`${kind}ButtonTarget`]
      button.classList.toggle("is-running", Boolean(running))
      if (running) {
        const seconds = Math.floor((new Date() - new Date(running.started_at)) / 1000)
        button.textContent = `${icon} ${formatMinutesSeconds(seconds)} ■ Arrêter`
      } else {
        button.textContent = label
      }
    }
  }

  #openDogPanel() {
    this.dogMood = null
    this.dogNameTarget.value = ""
    this.dogPanelTitleTarget.textContent = `🐕 Chien n°${this.encounters.length + 1} ?`
    this.#showMoods()
    this.dogPanelTarget.hidden = false
  }

  #hideDogPanel() {
    this.pendingEncounter = null
    this.dogPanelTarget.hidden = true
    this.dogNameTarget.blur() // closes the phone keyboard
  }

  #showMoods() {
    this.moodButtonTargets.forEach((button) => {
      const chosen = button.dataset.trackingMoodParam === this.dogMood
      button.classList.toggle("is-chosen", chosen)
      button.setAttribute("aria-pressed", chosen)
    })
  }

  #showDogsCount() {
    this.dogsCountTarget.textContent = this.encounters.length
  }

  #showStatus(status) {
    this.statusTarget.textContent = STATUSES[status]
  }
}

// The Capacitor plugin, only inside the Android app (the app injects window.Capacitor into the page).
function backgroundGeolocation() {
  const capacitor = window.Capacitor
  if (!capacitor?.isPluginAvailable?.("BackgroundGeolocation")) return null

  return capacitor.Plugins.BackgroundGeolocation
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

// 192 -> "03:12"
function formatMinutesSeconds(seconds) {
  return [Math.floor(seconds / 60), seconds % 60].map((n) => String(n).padStart(2, "0")).join(":")
}
