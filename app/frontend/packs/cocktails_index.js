function handleDeletion(event) {
  const deletedId = event.detail[0]['deleted_id'];

  const toDelete = document.querySelector(`#cocktail_${deletedId}`);
  if (toDelete === null) {
    return;
  }

  toDelete.remove();

  let toastTemplateDoc = document.querySelector("div[data-toast-template]");
  let toastDoc = toastTemplateDoc.cloneNode(true);
  toastDoc.querySelector("span[data-toast-body]").innerHTML = `${event.detail[0]['deleted_name']} deleted!`;

  let toastDestination = document.getElementById("toastDestination");
  toastDestination.appendChild(toastDoc);
  let toast = new bootstrap.Toast(toastDoc);

  toast.show();
}

function handleFavorited(event) {
  const favoritedId = event.detail[0]['favorited_id'];

  const toFavorite = document.querySelector(`#cocktail_${favoritedId}`);
  if (toFavorite === null) {
    return;
  }

  let column = toFavorite.querySelector(`.favorite-column`);
  column.innerHTML = '&#x2B50;';
}

function handleUnFavorited(event) {
  const favoritedId = event.detail[0]['favorited_id'];

  const toFavorite = document.querySelector(`#cocktail_${favoritedId}`);
  if (toFavorite === null) {
    return;
  }

  let column = toFavorite.querySelector(`.favorite-column`);
  column.innerHTML = '';
}

function handleToggleState(_event) {
  let user_only_state = document.querySelector('#userRecipesOnlySwitch').checked;
  let shared_only_state = document.querySelector('#sharedRecipesOnlySwitch').checked;

  let myCollapse = document.getElementById('toggleHelpCollapse');
  let bsCollapse = new bootstrap.Collapse(myCollapse, { toggle: false });

  if (user_only_state && shared_only_state) {
    bsCollapse.show();
  } else {
    bsCollapse.hide();
  }
}

window.addEventListener("turbolinks:load", () => {
  const toggles = document.querySelector('#toggles');

  toggles.addEventListener("click", handleToggleState);
  handleToggleState();

  const cocktailTable = document.querySelector("#cocktailsTable");

  if (cocktailTable === null) {
    return;
  }

  cocktailTable.addEventListener("ajax:success", (event) => {
    const action = event.detail[0]['action'];

    switch (action) {
      case "deleted":
        handleDeletion(event);
        break;
      case "favorited":
        handleFavorited(event);
        break;
      case "unfavorited":
        handleUnFavorited(event);
        break;
    }
  });

  cocktailTable.addEventListener("ajax:error", () => {
    cocktailTable.insertAdjacentHTML("beforeend", "<p>ERROR</p>");
  });

  const select2Config = {
    theme: 'bootstrap-5'
  };

  $('.ingredient-select').select2(select2Config);
});