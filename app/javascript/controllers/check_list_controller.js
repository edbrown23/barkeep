import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="check-list"
export default class extends Controller {
  static get targets() {
    return [ "input", "allState" ]
  }

  connect() {
  }

  allClicked() {
    var allChecked = this.allStateTarget.checked;
    this.inputTargets.forEach(element => {
      element.checked = allChecked;
    });
  }
}
