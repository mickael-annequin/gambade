import { Controller } from "@hotwired/stimulus"

// "📸 Ajouter des photos": as soon as photos are chosen in the gallery, they are sent
// (no extra "Envoyer" button), with a message because big photos take a few seconds.
export default class extends Controller {
  static targets = ["input", "button", "label"]

  send() {
    const count = this.inputTarget.files.length
    if (count === 0) return

    // Only the text changes: the file field is inside the button, replacing everything would remove the photos.
    this.labelTarget.textContent = count > 1 ? `⏳ Envoi de ${count} photos…` : "⏳ Envoi de la photo…"
    this.buttonTarget.classList.add("is-sending")
    this.element.requestSubmit()
  }
}
