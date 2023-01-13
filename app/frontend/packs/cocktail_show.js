function toastHTML(cocktail_name, reagents) {

  return `
    <p>${cocktail_name} made!</p>
    <p>Reagents used:</p>
    <ul>
      ${reagents.reduce( (previousValue, currentValue) => { return `${previousValue}<li>${currentValue}</li>`}, "") }
    </ul>
  `;
}

function updateCounter(new_count) {
  document.getElementById("made_count").innerHTML = new_count
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

window.addEventListener("turbolinks:load", () => {
  let makeCocktail = document.getElementById("make_cocktail_link");
  document.addEventListener("ajax:success", (event) => {
    var myModal = bootstrap.Modal.getInstance(document.getElementById('madeThisModal'), {});
    myModal.hide();

    let toastTemplateDoc = document.querySelector("div[data-toast-template]");
    let toastDoc = toastTemplateDoc.cloneNode(true);
    toastDoc.querySelector("span[data-toast-body]").innerHTML = toastHTML(event.detail[0]['cocktail_name'], event.detail[0]['reagents_used']);

    let toastDestination = document.getElementById("toastDestination");
    toastDestination.appendChild(toastDoc);
    let toast = new bootstrap.Toast(toastDoc);

    toast.show();

    updateCounter(event.detail[0]['made_count']);
  });

  document.addEventListener("ajax:error", () => {
    var myModal = bootstrap.Modal.getInstance(document.getElementById('madeThisModal'), {});
    myModal.toggle();
    makeCocktail.insertAdjacentHTML("beforeend", "<p>ERROR</p>");
  });

  // Modal setup
  const modalButton = document.querySelector('.made-this-button');
  modalButton.addEventListener("click", (event) => {
    const cocktailId = event.target.dataset.cocktailId;
    fetch(`${cocktailId}/pre_make_drink.json`)
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
  });
});