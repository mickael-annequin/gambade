import { Controller } from "@hotwired/stimulus"

const SWIPE_PIXELS = 50 // a finger move shorter than this is a tap, not a swipe

// Shows the walk photos full screen, one at a time: opened from the gallery or from the map,
// arrows or a swipe to go to the previous/next photo, ✕ (or the phone "back" gesture) to close.
export default class extends Controller {
  static targets = [ "dialog", "image", "caption", "previous", "next", "deleteForm" ]
  static values = { photos: Array } // [{ id: 12, image: url, time: "📷 18h30", delete_url: "/walks/3/photos/12" }, ...]

  // A gallery thumbnail (data-photo-viewer-id-param).
  open({ params: { id } }) {
    this.#show(this.photosValue.findIndex((photo) => photo.id === id))
  }

  // A photo marker on the map ("map:photo" event).
  openFromMap({ detail: { id } }) {
    this.open({ params: { id } })
  }

  // Also before Turbo keeps a copy of the page (it would come back with the viewer open).
  close() {
    this.dialogTarget.close()
  }

  // A tap on the black background (not on the photo or a button) closes too.
  closeOnBackground(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  previous() {
    if (this.index > 0) this.#show(this.index - 1)
  }

  next() {
    if (this.index < this.photosValue.length - 1) this.#show(this.index + 1)
  }

  touchStart(event) {
    this.touchStartX = event.changedTouches[0].clientX
  }

  // Swipe left → next photo, swipe right → previous photo.
  touchEnd(event) {
    const moved = event.changedTouches[0].clientX - this.touchStartX
    if (moved < -SWIPE_PIXELS) this.next()
    if (moved > SWIPE_PIXELS) this.previous()
  }

  #show(index) {
    if (index < 0) return

    this.index = index
    const photo = this.photosValue[index]
    this.imageTarget.src = photo.image
    this.captionTarget.textContent = `${photo.time} · ${index + 1}/${this.photosValue.length}`
    this.deleteFormTarget.action = photo.delete_url
    this.previousTarget.disabled = index === 0
    this.nextTarget.disabled = index === this.photosValue.length - 1
    if (!this.dialogTarget.open) this.dialogTarget.showModal()
  }
}
