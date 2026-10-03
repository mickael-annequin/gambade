import { Controller } from "@hotwired/stimulus"
import { loadWalk, clearWalk } from "walk_storage"

// On the home page: offers to resume a walk still saved in the phone.
// The display is always rebuilt from the phone's storage, because Turbo may show
// a cached copy of this page that was already modified.
export default class extends Controller {
  static targets = ["banner", "message", "startButton"]
  static values = { startLabel: String }

  connect() {
    this.#render()
  }

  abandon() {
    if (!confirm("Abandonner cette balade ? Elle sera perdue.")) return

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

    const startTime = new Date(walk.startedAt).toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })
    this.messageTarget.textContent = walk.endedAt
      ? `Ta balade de ${startTime} est terminée mais pas encore enregistrée.`
      : `Une balade est en cours depuis ${startTime}.`
    this.startButtonTarget.textContent = walk.endedAt ? "↻ Enregistrer la balade" : "▶ Reprendre la balade"
  }
}
