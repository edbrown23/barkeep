// TODO: should move all this into a shared lib
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

window.addEventListener("turbolinks:load", () => {
  lib.load_availability('/shared_cocktails_async');
  lib.load_availability('/cocktails_async');

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
})