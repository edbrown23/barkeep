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


window.addEventListener("turbolinks:load", () => {
  let makeCocktail = document.getElementById("make_cocktail_link");
  document.addEventListener("ajax:success", (event) => {
    var myModal = bootstrap.Modal.getInstance(document.getElementById('madeThisModal'), {});
    myModal.toggle();

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
  modalButton.addEventListener("click", lib.made_this_modal_loader.bind(this, '/cocktails'));
});