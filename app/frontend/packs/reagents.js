window.addEventListener("turbolinks:load", () => {
  const reagentsTable = document.querySelector("#reagentsTable");

  if (!reagentsTable) {
    return;
  }

  reagentsTable.addEventListener("ajax:success", (event) => {
    const refilledId = event.detail[0]['reagent_id'];

    const toRefill = document.querySelector(`#reagent_${refilledId}`);
    if (!toRefill) {
      return;
    }

    toRefill.querySelector("td[data-volume-row]").innerHTML = event.detail[0]['new_volume'];

    let toastTemplateDoc = document.querySelector("div[data-toast-template]");
    let toastDoc = toastTemplateDoc.cloneNode(true);
    toastDoc.querySelector("span[data-toast-body]").innerHTML = `${event.detail[0]['reagent_name']} refilled!`;

    let toastDestination = document.getElementById("toastDestination");
    toastDestination.appendChild(toastDoc);
    let toast = new bootstrap.Toast(toastDoc);

    toast.show();
  });

  reagentsTable.addEventListener("ajax:error", () => {
    reagentsTable.insertAdjacentHTML("beforeend", "<p>ERROR</p>");
  });
});