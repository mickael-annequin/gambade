import { Controller } from "@hotwired/stimulus"

// "Couper la fin": a slider to choose where the walk really ended.
// It tells the map where to show the cut, with a "trim:moved" event.
export default class extends Controller {
  static targets = ["slider", "endedAt", "summary"]
  static values = { progress: Array } // [{ at, time, meters, coordinates }, ...] in time order

  connect() {
    this.sliderTarget.max = this.progressValue.length - 1
    this.sliderTarget.value = this.progressValue.length - 1
    this.move()
  }

  move() {
    const point = this.progressValue[this.sliderTarget.value]
    const km = (point.meters / 1000).toFixed(1).replace(".", ",")
    this.endedAtTarget.value = point.at
    this.summaryTarget.textContent = `Fin de la balade à ${point.time} · ${km} km`
    this.dispatch("moved", { detail: { coordinates: point.coordinates } })
  }
}
