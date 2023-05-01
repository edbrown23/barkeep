import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

// Connects to data-controller="toast"
export default class extends Controller {
  connect() {
    this.toast = new bootstrap.Toast(this.element)
    this.open();
  }

  open() {
    this.toast.show()
  }
  
  remove() {
    this.element.remove()
  }
}
