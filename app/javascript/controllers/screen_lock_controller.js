import { Controller } from "@hotwired/stimulus"

// "🔒 Verrouiller" during a walk: a veil catches every touch, so a phone in a pocket
// cannot press any button. Unlocking needs a long press on 🔓 (a pocket rarely does that).
// The GPS keeps working: only the touches are blocked.
export default class extends Controller {
  static targets = ["overlay", "holdButton"]
  static values = { holdMilliseconds: { type: Number, default: 1500 } }

  lock() {
    this.overlayTarget.hidden = false
    navigator.vibrate?.(60)
  }

  // Finger down on 🔓: the button fills up (CSS), and unlocks if the finger stays long enough.
  startHold(event) {
    event.preventDefault() // no text selection or long-press menu
    this.holdButtonTarget.classList.add("is-holding")
    this.holdTimer = setTimeout(() => this.#unlock(), this.holdMillisecondsValue)
  }

  // Finger lifted (or slid away) too early: nothing happens.
  cancelHold() {
    clearTimeout(this.holdTimer)
    this.holdButtonTarget.classList.remove("is-holding")
  }

  disconnect() {
    clearTimeout(this.holdTimer)
  }

  #unlock() {
    this.cancelHold()
    this.overlayTarget.hidden = true
    navigator.vibrate?.([60, 60, 60])
  }
}
