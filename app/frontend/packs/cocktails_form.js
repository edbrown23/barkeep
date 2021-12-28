function getRandomInt(min, max) {
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min) + min); //The maximum is exclusive and the minimum is inclusive
}

function setupDestroyButton(reagentDoc, docId) {
  const deleteButton = reagentDoc.querySelector(".delete-button");
  deleteButton.dataset.docId = docId;

  deleteButton.addEventListener("click", (event) => {
    const buttonClicked = event.target;

    const reagentSection = document.getElementById(buttonClicked.dataset.docId);
    reagentSection.remove();
  });
}

window.addEventListener("load", () => {
  const moreIngredientsTrigger = document.querySelector("#more-ingredients-trigger");

  // This is the full setup of listeners
  moreIngredientsTrigger.addEventListener("click", (event) => {
    event.preventDefault();

    const template = document.querySelector("#base-reagent-group");

    const duplicated = template.cloneNode(true);
    const docId = getRandomInt(2, 100000);
    duplicated.id = docId;
    duplicated.hidden = false;

    setupDestroyButton(duplicated, docId)

    const ingredientsElement = document.querySelector("#ingredients");
    ingredientsElement.appendChild(duplicated);
  })

  // This is the setup for existing ingredients
  const existingIngredients = document.querySelectorAll("[data-edit-ingredients='true']");
  existingIngredients.forEach((element) => {
    setupDestroyButton(element, element.id);
  });
});