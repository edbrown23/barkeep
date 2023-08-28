import { Controller } from "@hotwired/stimulus"

const select2Config = {
  theme: 'bootstrap-5',
  tags: true,
  createTag: (params) => {
    // probably don't need jquery here
    var term = $.trim(params.term);

    if (term === '') {
      return null;
    }

    return {
      id: term,
      text: term,
      newTag: true
    }
  }
};

// Connects to data-controller="ingredients-select"
export default class extends Controller {
  static get targets() {
    return [ "select" ]
  }

  connect() {
    // we don't want to initialize select2 on the hidden ingredient input
    if (this.element.id === 'base-reagent-group') {
      return;
    }
    this.select = $(this.selectTarget).select2(select2Config);
    this.select.on('select2:select', this.newTagHandler);
  }

  newTagHandler(event) {
    if (event.params.data['newTag'] === undefined) {
      return;
    }

    const selected = event.target.selectedOptions;
    const newOption = Array.from(selected).find(value => value.innerHTML === event.params.data['id']);
    newOption.setAttribute('new-tag', true);
  }
}
