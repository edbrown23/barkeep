window.addEventListener("turbolinks:load", () => {
  const cocktailTable = document.querySelector("#cocktailsTable");

  if (cocktailTable === null) {
    return;
  }

  cocktailTable.addEventListener("ajax:success", (event) => {
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
  });

  cocktailTable.addEventListener("ajax:error", () => {
    cocktailTable.insertAdjacentHTML("beforeend", "<p>ERROR</p>");
  });
});