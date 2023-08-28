function getRandomInt(min, max) {
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min) + min); //The maximum is exclusive and the minimum is inclusive
}

function handleDelete(buttonClicked, event) {
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

function handleMoreIngredients(event) {
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

  duplicated.querySelector(".ingredient-select").id = `select-${docId}`;

  // setup required values, which can't be set on the hidden form
  duplicated.querySelector(".ingredient-select").setAttribute('required', true);
  duplicated.querySelector(".amount-input").setAttribute('required', true);

  const ingredientsElement = document.querySelector("#ingredients");
  ingredientsElement.appendChild(duplicated);
}

function handleQuickSelect(buttonClicked, event) {
  let groupClicked = event.target.parentElement.parentElement.parentElement;

  groupClicked.querySelector('.amount-input').value = buttonClicked.dataset.amount;
  groupClicked.querySelector('.unit-input').value = buttonClicked.dataset.unit;
}

function handleClicks(event) {
  let buttonClicked = event.target;
  let action = buttonClicked.dataset.action;

  switch (action) {
    case "more-ingredients":
      handleMoreIngredients(event);
      break;
    case "delete-reagent":
      handleDelete(buttonClicked, event);
      break;
    case "quick-select":
      handleQuickSelect(buttonClicked, event);
      break;
  }
}

function parseForm() {
  const allGroups = Array.from(document.querySelectorAll(".ingredient-group"));
  const parsedGroups = allGroups.reduce((accumulator, currentGroup) => {
    if (currentGroup.hidden) {
      return accumulator;
    }

    const selectedOptions = Array.from(currentGroup.querySelector('.ingredient-select').selectedOptions);
    const tags = selectedOptions.map((value) => {
      const tagObject = {
        tag: value.value
      }
      if (value.getAttribute('new-tag')) {
        tagObject['new'] = true;
      }
      return tagObject;
    });
    const amount = currentGroup.querySelector('.amount-input').value;
    const unit = currentGroup.querySelector('.unit-input').value;
    accumulator.push({
      tags: tags,
      amount: amount,
      unit: unit
    });
    return accumulator;
  }, []);

  const cocktailName = document.querySelector('#recipe_name').value;

  return {
    name: cocktailName,
    source: 'cocktail_create',
    amounts: parsedGroups
  };
}

function determineMethod() {
  const maybeMethod = document.getElementsByName('_method')[0];
  if (maybeMethod === undefined) {
    return 'post';
  }

  return maybeMethod.value;
}

function handleFormSubmission(event) {
  // Stop it from submitting to rails the normal way
  event.preventDefault();

  const csrfToken = document.getElementsByName('csrf-token')[0].content;
  const url = document.querySelector('form').action;
  const method = determineMethod();

  const toSubmit = parseForm();

  // TODO: I'm going to need to handle auth errors here like I did with the with the modal
  fetch(url, {
    method: method.toUpperCase(),
    headers: {
      'X-CSRF-Token': csrfToken,
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(toSubmit)
  })
  .then((response) => response.json())
  .then((json) => window.location = json['redirect_url']);
}

window.addEventListener("turbo:load", () => {
  // This little block just ensures we don't register the 'click' handlers more than once with
  // turbo. I don't know if this shit is even necessary
  let reagentTemplate = document.getElementById('base-reagent-group');
  if (!reagentTemplate) {
    return;
  }

  if (reagentTemplate.dataset.duplicateConfigured) {
    return;
  }
  reagentTemplate.dataset.duplicateConfigured = true;

  // This is the setup for existing ingredients
  const existingIngredients = document.querySelectorAll("[data-edit-ingredients='true']");
  existingIngredients.forEach((element) => {
    element.querySelector(".delete-button").dataset.docId = element.id;
  });

  document.addEventListener("click", handleClicks);

  // The following sets up the form submission logic
  document.querySelector("#cocktailForm").addEventListener("submit", handleFormSubmission);
});
