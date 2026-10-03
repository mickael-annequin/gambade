import { Controller } from "@hotwired/stimulus"
import { loadWalk, clearWalk } from "walk_storage"

// On the home page: offers to resume a walk still saved in the phone.
export default class extends Controller {
  static targets = ["banner", "message", "startButton"]

  connect() {
    this.startLabel = this.startButtonTarget.textContent
    const walk = loadWalk()
    if (!walk) return

    const startTime = new Date(walk.startedAt).toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })
    this.messageTarget.textContent = walk.endedAt
      ? `Ta balade de ${startTime} est terminée mais pas encore enregistrée.`
      : `Une balade est en cours depuis ${startTime}.`
    this.startButtonTarget.textContent = walk.endedAt ? "↻ Enregistrer la balade" : "▶ Reprendre la balade"
    this.bannerTarget.hidden = false
  }

  abandon() {
    if (!confirm("Abandonner cette balade ? Elle sera perdue.")) return

    clearWalk()
    this.bannerTarget.hidden = true
    this.startButtonTarget.textContent = this.startLabel
  }
}
