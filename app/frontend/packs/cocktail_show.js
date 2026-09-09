import { errorToastHandler } from "../js/lib/shared";

if (!window.cocktailErrorHandlerRegistered) {
  document.addEventListener("ajax:error", (event) => {
    if (!document.querySelector('[data-toast-error-template]')) return;
    const modal = document.getElementById('madeThisModal');
    if (modal) bootstrap.Modal.getInstance(modal)?.hide();
    errorToastHandler(document, event.detail[1]);
  });
  window.cocktailErrorHandlerRegistered = true;
}
