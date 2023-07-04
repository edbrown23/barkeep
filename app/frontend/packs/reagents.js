window.addEventListener("turbo:load", () => {
  const reagentsTable = document.querySelector("#reagentsTable");

  if (!reagentsTable) {
    return;
  }

  reagentsTable.addEventListener("ajax:success", (event) => {
    const refilledId = event.detail[0]['reagent_id'];
    const action = event.detail[0]['action'];

    const toRefill = document.querySelector(`#reagent_${refilledId}`);
    if (!toRefill) {
      return;
    }

    let visible_action = 'unknown';

    if (action === 'refill') {
      visible_action = 'refilled';
    } else if (action === 'empty') {
      visible_action = 'emptied';
    }
    toRefill.querySelector("td[data-volume-row]").innerHTML = event.detail[0]['new_volume'];

    let toastTemplateDoc = document.querySelector("div[data-toast-template]");
    let toastDoc = toastTemplateDoc.cloneNode(true);
    toastDoc.querySelector("span[data-toast-body]").innerHTML = `${event.detail[0]['reagent_name']} ${visible_action}!`;

    let toastDestination = document.getElementById("toastDestination");
    toastDestination.appendChild(toastDoc);
    let toast = new bootstrap.Toast(toastDoc);

    toast.show();
  });

  reagentsTable.addEventListener("ajax:error", () => {
    reagentsTable.insertAdjacentHTML("beforeend", "<p>ERROR</p>");
  });

  const select2Config = {
    theme: 'bootstrap-5'
  };

  $('.reagent-select').select2(select2Config);
});