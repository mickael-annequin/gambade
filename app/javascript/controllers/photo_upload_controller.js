import { Controller } from "@hotwired/stimulus"
import { parse } from "exifr"

// "📸 Ajouter des photos": as soon as photos are chosen in the gallery, they are sent
// (no extra "Envoyer" button), with a message because big photos take a few seconds.
// Before sending, the time each photo was taken is read from the photo itself (EXIF data):
// the server uses it to place the photo on the track.
export default class extends Controller {
  static targets = ["input", "button", "label"]

  async send() {
    const files = [ ...this.inputTarget.files ]
    if (files.length === 0) return

    // Only the text changes: the file field is inside the button, replacing everything would remove the photos.
    this.labelTarget.textContent = files.length > 1 ? `⏳ Envoi de ${files.length} photos…` : "⏳ Envoi de la photo…"
    this.buttonTarget.classList.add("is-sending")

    const takenAts = await Promise.all(files.map((file) => this.#takenAt(file)))
    this.#addTakenAtFields(takenAts)
    this.element.requestSubmit()
  }

  // The time the photo was taken, as "2026-10-04T09:15:00.000Z", or "" if the photo doesn't say.
  async #takenAt(file) {
    try {
      const exif = await parse(file, [ "DateTimeOriginal" ])
      return exif?.DateTimeOriginal?.toISOString() ?? ""
    } catch {
      return "" // not a photo from a camera (e.g. a screenshot): it is kept, just not placed
    }
  }

  // One hidden field per photo, in the same order as the photos.
  #addTakenAtFields(takenAts) {
    this.element.querySelectorAll(".photo-taken-at").forEach((field) => field.remove())
    takenAts.forEach((takenAt) => {
      const field = document.createElement("input")
      field.type = "hidden"
      field.name = "walk_photos[taken_ats][]"
      field.className = "photo-taken-at"
      field.value = takenAt
      this.element.append(field)
    })
  }
}
