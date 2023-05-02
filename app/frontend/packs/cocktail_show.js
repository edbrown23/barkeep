import { errorToastHandler } from "../js/lib/shared";

window.addEventListener("turbo:load", () => {
  document.addEventListener("ajax:error", (event) => {
    errorToastHandler(document, event.detail[1]);
  });
});