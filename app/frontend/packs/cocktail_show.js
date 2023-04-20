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

function proposeToShareToastHTML() {
  return `
    <p>Thanks for your submission!</p>
    <p>We'll consider it for the shared cocktails list!</p> 
  `
}

function updateCounter(new_count) {
  document.getElementById("made_count").innerHTML = new_count
}

function showToast(title, body) {
  let toastTemplateDoc = document.querySelector("div[data-toast-template]");
  let toastDoc = toastTemplateDoc.cloneNode(true);

  toastDoc.querySelector("span[data-toast-body]").innerHTML = body;

  let toastDestination = document.getElementById("toastDestination");
  toastDestination.appendChild(toastDoc);
  let toast = new bootstrap.Toast(toastDoc);

  toast.show();
}

function handleMakeDrink(event) {
  var myModal = bootstrap.Modal.getInstance(document.getElementById('madeThisModal'), {});
  myModal.hide();

  showToast('', makeDrinkToastHTML(event.detail[0]['cocktail_name'], event.detail[0]['reagents_used']));

  updateCounter(event.detail[0]['made_count']);
}

function handleProposeToShare(_event) {
  showToast('', proposeToShareToastHTML());
}

window.addEventListener("turbo:load", () => {
  let makeCocktail = document.getElementById("make_cocktail_link");
  document.addEventListener("ajax:success", (event) => {
    let action = event.detail[0]['action'];

    switch (action) {
      case "make_drink":
        handleMakeDrink(event);
        break;
      case "propose_to_share":
        handleProposeToShare(event);
        break;
      case "make_permanent":
        console.log("make permanent shouldn't be ending up here")
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

  // Modal setup
  const modalButton = document.querySelector('.made-this-button');
  modalButton.addEventListener("click", lib.made_this_modal_loader.bind(this, '/cocktails', null));
});