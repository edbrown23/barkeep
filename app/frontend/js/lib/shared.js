export function load_availability(base_url) {
  fetch(`${base_url}/available_counts.json${window.location.search}`)
    .then((response) => response.json())
    .then((json) => {
      Object.keys(json.available_counts).forEach((key) => {
        let row = document.querySelector(`#cocktail_${key}_count_row`);
        if (!row) {
          return;
        }

        let value = json.available_counts[key];
        row.innerHTML = `${value.available} of ${value.required}`;
      });
    })
}

export function errorToastHandler(subDocument, error) {
  let toastTemplateDoc = subDocument.querySelector("div[data-toast-error-template]");
  let toastDoc = toastTemplateDoc.cloneNode(true);

  toastDoc.querySelector("span[data-toast-body]").innerHTML = error;

  let toastDestination = document.getElementById("errorToastDestination");
  toastDestination.appendChild(toastDoc);
  let toast = new bootstrap.Toast(toastDoc);

  toast.show();
}

function cheersToastHTML(cocktail_name, reagents) {
  return `
    <p>${cocktail_name} made!</p>
    <p>Reagents used:</p>
    <ul>
      ${reagents.reduce( (previousValue, currentValue) => { return `${previousValue}<li>${currentValue}</li>`}, "") }
    </ul>
  `;
}

export function cheersToastHander(subDocument, detail) {
  let toastTemplateDoc = document.querySelector("div[data-toast-template]");
  let toastDoc = toastTemplateDoc.cloneNode(true);
  toastDoc.querySelector("span[data-toast-body]").innerHTML = cheersToastHTML(detail[0]['cocktail_name'], detail[0]['reagents_used']);

  let toastDestination = document.getElementById("toastDestination");
  toastDestination.appendChild(toastDoc);
  let toast = new bootstrap.Toast(toastDoc);

  toast.show();
}