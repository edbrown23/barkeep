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
  let makeCocktail = document.getElementById("make_cocktail_link");
  makeCocktail.addEventListener("ajax:success", (event) => {
    let toastTemplateDoc = document.querySelector("div[data-toast-template]");
    let toastDoc = toastTemplateDoc.cloneNode(true);
    toastDoc.querySelector("span[data-toast-body]").innerHTML = toastHTML(event.detail[0]['cocktail_name'], event.detail[0]['reagents_used']);

    let toastDestination = document.getElementById("toastDestination");
    toastDestination.appendChild(toastDoc);
    let toast = new bootstrap.Toast(toastDoc);

    toast.show();
  });

  makeCocktail.addEventListener("ajax:error", () => {
    makeCocktail.insertAdjacentHTML("beforeend", "<p>ERROR</p>");
  });
});