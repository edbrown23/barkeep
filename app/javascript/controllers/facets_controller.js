import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="facets"
export default class extends Controller {
  connect() {
    this.tag_value = this.element.dataset.tag;
  }

  clicked() {
    let selector = $('.ingredient-select');
    let currentTags = selector.select2('data').reduce(
      (accumulator, currentValue) => {
        accumulator.push(currentValue.id);

        return accumulator;
      },
      []
    )

    currentTags.push(this.tag_value);

    selector.val(currentTags);
    selector.trigger('change');
  }
}
