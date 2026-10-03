// Keeps the walk in progress in the phone (localStorage), so nothing is lost
// if the page closes, the browser crashes or the battery runs out.
const KEY = "gambade:walk-in-progress"

export function loadWalk() {
  try {
    return JSON.parse(localStorage.getItem(KEY))
  } catch {
    return null
  }
}

export function saveWalk(walk) {
  try {
    localStorage.setItem(KEY, JSON.stringify(walk))
  } catch {
    // Storage full or disabled: the walk still works, it is just not protected.
  }
}

export function clearWalk() {
  try {
    localStorage.removeItem(KEY)
  } catch {
    // Nothing to do.
  }
}
