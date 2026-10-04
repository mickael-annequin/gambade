import { Controller } from "@hotwired/stimulus"
import { Chart, BarController, BarElement, CategoryScale, LinearScale, Tooltip } from "chart.js"

Chart.register(BarController, BarElement, CategoryScale, LinearScale, Tooltip)

const BAR_COLOR = "#E08E45" // ocre, like the tracks
const TEXT_COLOR = "rgba(59, 49, 39, 0.7)" // bark, muted
const GRID_COLOR = "rgba(59, 49, 39, 0.08)"

// One bar chart of the stats page (km, time or dogs per week/month). Touching a bar shows its value.
export default class extends Controller {
  static targets = [ "canvas" ]
  static values = {
    labels: Array, // ["29 sept.", "6 oct.", …]
    data: Array, // [2.3, 0, 4.1, …]
    unit: String, // "km"
    minutes: Boolean // values are minutes: shown as "1 h 05"
  }

  connect() {
    this.chart = new Chart(this.canvasTarget, {
      type: "bar",
      data: {
        labels: this.labelsValue,
        datasets: [ { data: this.dataValue, backgroundColor: BAR_COLOR, borderRadius: 4, maxBarThickness: 22 } ]
      },
      options: {
        maintainAspectRatio: false,
        animation: false,
        scales: {
          x: { grid: { display: false }, ticks: { color: TEXT_COLOR, maxRotation: 0, autoSkipPadding: 8 } },
          y: { beginAtZero: true, grid: { color: GRID_COLOR }, border: { display: false },
               ticks: { color: TEXT_COLOR, maxTicksLimit: 4, callback: (value) => this.#format(value) } }
        },
        plugins: {
          tooltip: { displayColors: false, callbacks: { label: ({ raw }) => this.#format(raw) } }
        }
      }
    })
  }

  // Free the chart when Turbo leaves the page.
  disconnect() {
    this.chart?.destroy()
  }

  #format(value) {
    if (!this.minutesValue) return `${value.toLocaleString("fr-FR")} ${this.unitValue}`

    const hours = Math.floor(value / 60)
    const minutes = String(Math.round(value % 60)).padStart(2, "0")
    return hours > 0 ? `${hours} h ${minutes}` : `${Math.round(value)} min`
  }
}
