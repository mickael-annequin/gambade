import { Controller } from "@hotwired/stimulus"
import { loadWalk, clearWalk } from "walk_storage"
import { confirmDialog } from "confirm_dialog"

// On the home page: offers to resume a walk still saved in the phone.
// The display is always rebuilt from the phone's storage, because Turbo may show
// a cached copy of this page that was already modified.
export default class extends Controller {
  static targets = ["banner", "message", "startButton"]
  static values = { startLabel: String }

  connect() {
    this.#render()
  }

  async abandon() {
    if (!(await confirmDialog("Abandonner cette balade ? Elle sera perdue."))) return

    clearWalk()
    this.#render()
  }

  #render() {
    const walk = loadWalk()
    this.bannerTarget.hidden = !walk
    if (!walk) {
      this.startButtonTarget.textContent = this.startLabelValue
      return
    }

    const startedAt = new Date(walk.startedAt)
    const startTime = `${startedAt.getHours()}h${String(startedAt.getMinutes()).padStart(2, "0")}`
    this.messageTarget.textContent = walk.endedAt
      ? `Ta balade de ${startTime} est terminée mais pas encore enregistrée.`
      : `Une balade est en cours (démarrée à ${startTime}, ${timeAgo(startedAt)}).`
    this.startButtonTarget.textContent = walk.endedAt ? "↻ Enregistrer la balade" : "▶ Reprendre la balade"
  }
}

// "il y a 3 min", "il y a 1 h 05"
function timeAgo(date) {
  const minutes = Math.max(0, Math.floor((new Date() - date) / 60000))
  if (minutes < 60) return `il y a ${minutes} min`

  return `il y a ${Math.floor(minutes / 60)} h ${String(minutes % 60).padStart(2, "0")}`
}
