import { Controller } from "@hotwired/stimulus"

// "−" and "+" buttons around a number field, so no keyboard is needed on the phone.
export default class extends Controller {
  static targets = ["input"]

  increment() {
    this.inputTarget.value = this.#value() + 1
  }

  decrement() {
    this.inputTarget.value = Math.max(0, this.#value() - 1)
  }

  #value() {
    return parseInt(this.inputTarget.value, 10) || 0
  }
}
