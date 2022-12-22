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