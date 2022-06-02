function getRandomInt(min, max) {
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min) + min); //The maximum is exclusive and the minimum is inclusive
}

function deleteIngredient(event) {
  let buttonClicked = event.target;
  let docId = buttonClicked.dataset.docId;

  if (!docId) {
    return;
  }

  let toRemove = document.getElementById(docId);
  if (!toRemove) {
    return;
  }

  toRemove.remove();
}

window.addEventListener("turbolinks:load", () => {
  // This little block just ensures we don't register the 'click' handlers more than once with
  // turbolinks. I don't know if this shit is even necessary
  let reagentTemplate = document.getElementById('base-reagent-group');
  if (!reagentTemplate) {
    return;
  }

  if (reagentTemplate.dataset.duplicateConfigured) {
    return;
  }
  reagentTemplate.dataset.duplicateConfigured = true;
  
  document.addEventListener("click", (event) => {
    let idHit = event.target.id;

    if (idHit != "more-ingredients-trigger") {
      return;
    }

    event.preventDefault();

    const template = document.querySelector("#base-reagent-group");

    const duplicated = template.cloneNode(true);
    const docId = getRandomInt(2, 100000);
    duplicated.id = docId;
    duplicated.hidden = false;

    duplicated.querySelector(".delete-button").dataset.docId = docId;

    const ingredientsElement = document.querySelector("#ingredients");
    ingredientsElement.appendChild(duplicated);
  });

  // This is the setup for existing ingredients
  const existingIngredients = document.querySelectorAll("[data-edit-ingredients='true']");
  existingIngredients.forEach((element) => {
    element.querySelector(".delete-button").dataset.docId = element.id;
  });

  document.addEventListener("click", deleteIngredient);
});
