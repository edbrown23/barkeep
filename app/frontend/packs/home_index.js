function toastHTML(cocktail_name, reagents) {

  return `
    <p>${cocktail_name} made!</p>
    <p>Reagents used:</p>
    <ul>
      ${reagents.reduce( (previousValue, currentValue) => { return `${previousValue}<li>${currentValue}</li>`}, "") }
    </ul>
  `;
}

window.addEventListener("turbolinks:load", () => {
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
    myModal.toggle();

    let toastTemplateDoc = document.querySelector("div[data-toast-template]");
    let toastDoc = toastTemplateDoc.cloneNode(true);
    toastDoc.querySelector("span[data-toast-body]").innerHTML = toastHTML(event.detail[0]['cocktail_name'], event.detail[0]['reagents_used']);

    let toastDestination = document.getElementById("toastDestination");
    toastDestination.appendChild(toastDoc);
    let toast = new bootstrap.Toast(toastDoc);

    toast.show();
  });

  cocktailsSection.addEventListener("ajax:error", () => {
    var myModal = bootstrap.Modal.getInstance(document.getElementById('madeThisModal'), {});
    myModal.toggle();
    cocktailsSection.insertAdjacentHTML("beforeend", "<p>ERROR</p>");
  });

  const modalButtons = document.querySelectorAll('.made-this-button');
  modalButtons.forEach((button) => button.addEventListener("click", (event) => {
    const baseRoute = event.target.dataset.preRoute;
    lib.made_this_modal_loader(baseRoute, event)
  }));
});