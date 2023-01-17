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

window.addEventListener("turbolinks:load", () => {
  document.addEventListener("ajax:success", (event) => {
    var myModal = bootstrap.Modal.getInstance(document.getElementById('madeThisModal'), {});
    myModal.toggle();

    let toastTemplateDoc = document.querySelector("div[data-toast-template]");
    let toastDoc = toastTemplateDoc.cloneNode(true);
    toastDoc.querySelector("span[data-toast-body]").innerHTML = makeDrinkToastHTML(event.detail[0]['cocktail_name'], event.detail[0]['reagents_used']);

    let toastDestination = document.getElementById("toastDestination");
    toastDestination.appendChild(toastDoc);
    let toast = new bootstrap.Toast(toastDoc);

    toast.show();

    updateCounters(event.detail[0]['made_count'], event.detail[0]['made_globally_count']);
  });

  let promoteCocktail = document.getElementById("promote_link");
  promoteCocktail.addEventListener("ajax:success", (event) => {
    let toastTemplateDoc = document.querySelector("div[data-toast-template]");
    let toastDoc = toastTemplateDoc.cloneNode(true);
    toastDoc.querySelector("span[data-toast-body]").innerHTML = promoteToastHTML(event.detail[0]['cocktail_name']);

    let toastDestination = document.getElementById("toastDestination");
    toastDestination.appendChild(toastDoc);
    let toast = new bootstrap.Toast(toastDoc);

    toast.show();
  });

  document.addEventListener("ajax:error", () => {
    var myModal = bootstrap.Modal.getInstance(document.getElementById('madeThisModal'), {});
    myModal.toggle();

    makeCocktail.insertAdjacentHTML("beforeend", "<p>ERROR</p>");
  });

  const modalButton = document.querySelector('.made-this-button');
  modalButton.addEventListener("click", lib.made_this_modal_loader.bind(this, '/cocktails'));
});