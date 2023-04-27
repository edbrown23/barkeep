import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="home-index"
export default class extends Controller {
  static get targets() {
    return [ "collapse" ]
  }

  connect() {
  }

  toggleCollapse() {
    let collapse = new bootstrap.Collapse(this.collapseTarget);
    collapse.toggle();
  }
}
