import { cheersToastHander, errorToastHandler } from "../js/lib/shared";

window.addEventListener("turbo:load", () => {
  // I bet this could be done with boostrap events instead
  document.addEventListener('click', (event) => {
    let buttonState = event.target.dataset.toggled;

    if (!buttonState) {
      return;
    }

    if (buttonState === 'false') {
      event.target.classList.remove("btn-outline-info");
      event.target.classList.add("btn-info");
      event.target.dataset.toggled = 'true';
    } else if (buttonState === 'true') {
      event.target.classList.remove("btn-info");
      event.target.classList.add("btn-outline-info");
      event.target.dataset.toggled = 'false';
    }
  });

  let cocktailsSection = document.getElementById("homeContainer");
  cocktailsSection.addEventListener("ajax:success", (event) => {
    var myModal = bootstrap.Modal.getInstance(document.getElementById('madeThisModal'), {});
    myModal.hide();

    cheersToastHander(document, event.detail);
  });

  cocktailsSection.addEventListener("ajax:error", (error) => {
    var myModal = bootstrap.Modal.getInstance(document.getElementById('madeThisModal'), {});
    myModal.hide();

    errorToastHandler(document, error.detail[1]);
  });

  const modalButtons = document.querySelectorAll('.made-this-button');
  modalButtons.forEach((button) => button.addEventListener("click", (event) => {
    const baseRoute = event.target.dataset.preRoute;
    lib.made_this_modal_loader(baseRoute, null, event);
  }));
});