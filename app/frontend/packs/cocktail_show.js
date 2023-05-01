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

function showToast(title, body) {
  let toastTemplateDoc = document.querySelector("div[data-toast-template]");
  let toastDoc = toastTemplateDoc.cloneNode(true);

  toastDoc.querySelector("span[data-toast-body]").innerHTML = body;

  let toastDestination = document.getElementById("toastDestination");
  toastDestination.appendChild(toastDoc);
  let toast = new bootstrap.Toast(toastDoc);

  toast.show();
}

function handleProposeToShare(_event) {
  showToast('', proposeToShareToastHTML());
}

window.addEventListener("turbo:load", () => {
  document.addEventListener("ajax:success", (event) => {
    let action = event.detail[0]['action'];

    switch (action) {
      case "propose_to_share":
        handleProposeToShare(event);
        break;
    }
  });

  document.addEventListener("ajax:error", (event) => {
    errorToastHandler(document, event.detail[1]);
  });
});