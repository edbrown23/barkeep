// More repeated code, gross
function load_availability() {
  fetch(`shared_cocktails_async/available_counts.json${window.location.search}`)
    .then((response) => response.json())
    .then((json) => {
      console.log(json);
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

window.addEventListener("turbolinks:load", () => {
  load_availability();
});