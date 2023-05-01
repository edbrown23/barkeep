import { errorToastHandler } from "../js/lib/shared";

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

  cocktailsSection.addEventListener("ajax:error", (error) => {
    var myModal = bootstrap.Modal.getInstance(document.getElementById('madeThisModal'), {});
    myModal.hide();

    errorToastHandler(document, error.detail[1]);
  });
});