import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="drink-making-form"
export default class extends Controller {
  static get targets() {
    return [ "collapse", "originalSelection", "checkbox" ]
  }

  connect() {
  }

  toggleCollapse() {
    let collapse = new bootstrap.Collapse(this.collapseTarget);
    collapse.toggle();

    this.originalSelectionTarget.disabled = this.checkboxTarget.checked;
  }
}
