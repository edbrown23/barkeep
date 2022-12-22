window.addEventListener("turbolinks:load", () => {
  lib.load_availability('/shared_cocktails_async');
  lib.load_availability('/cocktails_async');
})