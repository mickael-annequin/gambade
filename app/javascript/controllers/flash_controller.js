import { Controller } from "@hotwired/stimulus"

// A message at the top of the page ("Notes enregistrées.") that fades out by itself.
export default class extends Controller {
  static values = { seconds: { type: Number, default: 4 } }

  connect() {
    this.timer = setTimeout(() => this.#fadeOut(), this.secondsValue * 1000)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  #fadeOut() {
    this.element.classList.add("is-hiding") // CSS fade (components/_flash.scss)
    this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
  }
}
