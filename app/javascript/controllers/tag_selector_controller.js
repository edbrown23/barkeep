import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tag-selector"
export default class extends Controller {
  connect() {
    let queryParams = new URLSearchParams(window.location.search);
    let selectedTags = queryParams.getAll('search_tags[]');

    let options = selectedTags.map( (e) => {
      return new Option(e, e, false, true);
    });

    let selector = $('.ingredient-select');
    options.forEach( (e) => {
      if (selector.find(`option[value=${e.value}]`).length == 0) {
        selector.append(e);
      }
    });
    selector.trigger('change');
  }
}
