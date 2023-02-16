export function load_availability(base_url) {
  fetch(`${base_url}/available_counts.json${window.location.search}`)
    .then((response) => response.json())
    .then((json) => {
      Object.keys(json.available_counts).forEach((key) => {
        let row = document.querySelector(`#cocktail_${key}_count_row`);
        if (!row) {
          return;
        }

        let value = json.available_counts[key];
        row.innerHTML = `${value.available} of ${value.required}`;
      });
    })
}

function reagentChoiceFormatter(amount) {
  return `
    <div class="choice-block mb-3">
      <p>${amount['tags']}<small> (${amount['required']} required): </small></p>
      <div class="input-group">
        <span class="input-group-text">Use: </span>
        <select class="form-select" name="bottles[chosen_id][]">
          ${amount['bottle_choices'].reduce( (previousValue, currentValue) => { return `${previousValue}<option value=${currentValue['id']}>${currentValue['name']} (${currentValue['volume_available']} available)</option>` }, "") }
        </select>
      </div>
    </div>
  `;
}

export function made_this_modal_loader(base_url, event) {
  const cocktailId = event.target.dataset.cocktailId;
  fetch(`${base_url}/${cocktailId}/pre_make_drink.json`)
    .then((response) => response.json())
    .then((json) => {
      // setup the modal
      document.getElementById('ModalTitle').innerHTML = `Let's make a ${json.name}`;

      // setup the form
      document.getElementById('makeDrinkForm').action = `/cocktails/${cocktailId}/make_drink.json`;

      const choices = document.getElementById('reagentChoice');
      // clear whatever was there before
      choices.innerHTML = "";

      const newBlocks = json['reagent_options'].reduce((previousValue, currentValue) => { return `${previousValue}${reagentChoiceFormatter(currentValue)}`}, "");
      choices.innerHTML = newBlocks;
      
      // show the modal
      var myModal = new bootstrap.Modal(document.getElementById('madeThisModal'), {});
      myModal.show();
    })
    .catch((error) => {
      errorToastHandler(document, error);
    })
}

export function errorToastHandler(subDocument, error) {
  let toastTemplateDoc = subDocument.querySelector("div[data-toast-error-template]");
  let toastDoc = toastTemplateDoc.cloneNode(true);

  toastDoc.querySelector("span[data-toast-body]").innerHTML = error;

  let toastDestination = document.getElementById("errorToastDestination");
  toastDestination.appendChild(toastDoc);
  let toast = new bootstrap.Toast(toastDoc);

  toast.show();
}