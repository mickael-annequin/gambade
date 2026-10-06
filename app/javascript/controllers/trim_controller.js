import { Controller } from "@hotwired/stimulus"

// "Couper la fin": a slider to choose where the walk really ended.
// When the walk came back near the start (a loop), the slider first covers only that part:
// fewer points under the finger, so it is easier to aim. "Voir toute la balade" gives the whole walk back.
// It tells the map where to show the cut ("trim:moved") and what to zoom on ("trim:focused").
export default class extends Controller {
  static targets = ["slider", "endedAt", "summary", "zoneHint", "toggle"]
  static values = {
    progress: Array, // [{ at, time, meters, coordinates }, ...] in time order
    zone: Object // { from, to, suggested }: indexes of the return near the start, or {} when none
  }

  connect() {
    this.wholeWalk = !this.#hasZone()
    this.#showRange(this.wholeWalk ? this.progressValue.length - 1 : this.zoneValue.suggested)
  }

  // ◀ ▶: one GPS point earlier or later (data-trim-by-param = -1 or 1).
  step({ params: { by } }) {
    this.sliderTarget.value = Number(this.sliderTarget.value) + by // the slider keeps it between min and max
    this.move()
  }

  move() {
    const point = this.progressValue[this.sliderTarget.value]
    const km = (point.meters / 1000).toFixed(2).replace(".", ",") // 10 m steps: each ◀ ▶ shows a change
    this.endedAtTarget.value = point.at
    this.summaryTarget.textContent = `Fin de la balade à ${point.time} · ${km} km`
    this.dispatch("moved", { detail: { coordinates: point.coordinates } })
  }

  // "Voir toute la balade" ⇄ "Revenir au retour près du départ": the chosen point stays chosen when it can.
  toggleZone() {
    this.wholeWalk = !this.wholeWalk
    const { from, to, suggested } = this.zoneValue
    const value = Number(this.sliderTarget.value)
    this.#showRange(this.wholeWalk || (value >= from && value <= to) ? value : suggested)
  }

  #showRange(value) {
    const [min, max] = this.wholeWalk ? [0, this.progressValue.length - 1] : [this.zoneValue.from, this.zoneValue.to]
    this.sliderTarget.min = min
    this.sliderTarget.max = max
    this.sliderTarget.value = value
    if (this.#hasZone()) {
      this.zoneHintTarget.hidden = this.wholeWalk
      this.toggleTarget.textContent = this.wholeWalk ? "Revenir au retour près du départ" : "Voir toute la balade"
    }
    const coordinates = this.progressValue.slice(min, max + 1).map((point) => point.coordinates)
    this.dispatch("focused", { detail: { coordinates } })
    this.move()
  }

  #hasZone() {
    return this.zoneValue.from !== undefined
  }
}
