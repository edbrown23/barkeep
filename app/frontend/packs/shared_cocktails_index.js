window.addEventListener("turbolinks:load", () => {
  const select2Config = {
    theme: 'bootstrap-5'
  };

  $('.ingredient-select').select2(select2Config);
});