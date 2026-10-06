// Our own "Oui / Non" window (the <dialog> of the layout), instead of the phone's plain confirm() and alert().
// Used by Turbo for every data-turbo-confirm (see application.js) and by the Stimulus controllers.

// Resolves to true for "Oui", false for "Non" (or the phone's back button).
export function confirmDialog(message) {
  return open(message, { cancelable: true })
}

// Only an "OK" button. Resolves when it is closed.
export function alertDialog(message) {
  return open(message, { cancelable: false })
}

function open(message, { cancelable }) {
  const dialog = document.getElementById("confirm-dialog")
  if (!dialog) return Promise.resolve(cancelable ? confirm(message) : alert(message))

  dialog.querySelector("[data-confirm-dialog-message]").textContent = message
  dialog.querySelector("[data-confirm-dialog-cancel]").hidden = !cancelable
  dialog.querySelector("[data-confirm-dialog-ok]").textContent = cancelable ? "Oui" : "OK"
  dialog.returnValue = ""
  dialog.showModal()

  return new Promise((resolve) => {
    dialog.addEventListener("close", () => resolve(dialog.returnValue === "ok"), { once: true })
  })
}
