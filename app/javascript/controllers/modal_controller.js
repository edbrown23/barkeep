import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  connect() {
    this.modal = bootstrap.Modal.getOrCreateInstance(this.element)
    this.opening = false
    this.closeRequested = false
    this.onShown = () => {
      this.opening = false
      if (this.closeRequested) {
        this.closeRequested = false
        this.modal.hide()
      }
    }
    this.element.addEventListener('shown.bs.modal', this.onShown)
  }

  disconnect() {
    this.element.removeEventListener('shown.bs.modal', this.onShown)
  }

  open() {
    if (this.element.classList.contains('show')) return
    this.opening = true
    this.modal.show()
  }

  close(event) {
    if (!event.detail.success) return
    // Bootstrap ignores hide() during the opening animation. A fast response
    // should still close the modal once that animation completes.
    if (this.opening) {
      this.closeRequested = true
    } else {
      this.modal.hide()
    }
  }
}
