import { errorToastHandler } from "../js/lib/shared";

function promoteToastHTML(cocktail_name) {

  return `
    <p>${cocktail_name} copied to your account!</p>
  `;
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

window.addEventListener("turbo:load", () => {
  document.addEventListener("ajax:success", (event) => {
    let action = event.detail[0]['action'];

    switch (action) {
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
});