import { Controller } from "@hotwired/stimulus"
import { Chart, LineController, LineElement, PointElement, LinearScale, Tooltip } from "chart.js"

Chart.register(LineController, LineElement, PointElement, LinearScale, Tooltip)

const LINE_COLOR = "#E08E45" // ocre, like the stats bars
const TEXT_COLOR = "rgba(59, 49, 39, 0.7)" // bark, muted
const GRID_COLOR = "rgba(59, 49, 39, 0.08)"
const DAY = 24 * 60 * 60 * 1000

// The weight curve on the dog page. The x axis is in days, so the gaps between weighings
// are to scale (3 months take more room than 1 week). Touching a point shows its date and weight.
export default class extends Controller {
  static targets = [ "canvas" ]
  static values = { points: Array } // [{ x: "2026-10-04", y: 24.3 }, ...], oldest first

  connect() {
    const data = this.pointsValue.map(({ x, y }) => ({ x: Date.parse(x), y }))
    this.chart = new Chart(this.canvasTarget, {
      type: "line",
      data: {
        datasets: [ {
          data, borderColor: LINE_COLOR, backgroundColor: LINE_COLOR,
          borderWidth: 2, pointRadius: 4, pointHoverRadius: 6, pointHitRadius: 16
        } ]
      },
      options: {
        maintainAspectRatio: false,
        animation: false,
        scales: {
          x: { type: "linear", min: data[0].x - DAY, max: data.at(-1).x + DAY, grid: { display: false },
               ticks: { color: TEXT_COLOR, maxTicksLimit: 4, maxRotation: 0, callback: (value) => this.#day(value) } },
          y: { grace: "10%", grid: { color: GRID_COLOR }, border: { display: false },
               ticks: { color: TEXT_COLOR, maxTicksLimit: 4, callback: (value) => this.#kg(value) } }
        },
        plugins: {
          tooltip: {
            displayColors: false,
            callbacks: { title: ([ item ]) => this.#day(item.raw.x), label: ({ raw }) => this.#kg(raw.y) }
          }
        }
      }
    })
  }

  // Free the chart when Turbo leaves the page.
  disconnect() {
    this.chart?.destroy()
  }

  #day(time) {
    return new Date(time).toLocaleDateString("fr-FR", { day: "numeric", month: "short", timeZone: "UTC" })
  }

  #kg(value) {
    return `${value.toLocaleString("fr-FR", { maximumFractionDigits: 1 })} kg`
  }
}
