import { errorToastHandler } from "../js/lib/shared";

function makeDrinkToastHTML(cocktail_name, reagents) {

  return `
    <p>${cocktail_name} made!</p>
    <p>Reagents used:</p>
    <ul>
      ${reagents.reduce( (previousValue, currentValue) => { return `${previousValue}<li>${currentValue}</li>`}, "") }
    </ul>
  `;
}

function promoteToastHTML(cocktail_name) {

  return `
    <p>${cocktail_name} copied to your account!</p>
  `;
}

function updateCounters(new_count, new_global_count) {
  document.getElementById("made_count").innerHTML = new_count
  document.getElementById("made_globally_count").innerHTML = new_count
}

function handleAddToAccount(event) {
  let toastTemplateDoc = document.querySelector("div[data-toast-template]");
  let toastDoc = toastTemplateDoc.cloneNode(true);
  toastDoc.querySelector("span[data-toast-body]").innerHTML = promoteToastHTML(event.detail[0]['cocktail_name']);

  let toastDestination = document.getElementById("toastDestination");
  toastDestination.appendChild(toastDoc);
  let toast = new bootstrap.Toast(toastDoc);

  toast.show();
}

function handleMakeDrink(event) {
  var myModal = bootstrap.Modal.getInstance(document.getElementById('madeThisModal'), {});
  myModal.dispose();

  let toastTemplateDoc = document.querySelector("div[data-toast-template]");
  let toastDoc = toastTemplateDoc.cloneNode(true);
  toastDoc.querySelector("span[data-toast-body]").innerHTML = makeDrinkToastHTML(event.detail[0]['cocktail_name'], event.detail[0]['reagents_used']);

  let toastDestination = document.getElementById("toastDestination");
  toastDestination.appendChild(toastDoc);
  let toast = new bootstrap.Toast(toastDoc);

  toast.show();

  updateCounters(event.detail[0]['made_count'], event.detail[0]['made_globally_count']);
}

window.addEventListener("turbolinks:load", () => {
  document.addEventListener("ajax:success", (event) => {
    let action = event.detail[0]['action'];

    switch (action) {
      case "make_drink":
        handleMakeDrink(event);
        break;
      case "add_to_account":
        handleAddToAccount(event);
        break;
    }
  });

  document.addEventListener("ajax:error", (event) => {
    var myModal = bootstrap.Modal.getInstance(document.getElementById('madeThisModal'), {});
    if (myModal) {
      myModal.dispose();
    }

    errorToastHandler(document, event.detail[1]);
  });

  const modalButton = document.querySelector('.made-this-button');
  modalButton.addEventListener("click", lib.made_this_modal_loader.bind(this, '/cocktails', null));
});