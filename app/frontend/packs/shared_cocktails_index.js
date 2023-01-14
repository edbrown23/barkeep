window.addEventListener("turbolinks:load", () => {
  lib.load_availability('shared_cocktails_async');

  const select2Config = {
    theme: 'bootstrap-5'
  };

  $('.ingredient-select').select2(select2Config);
});