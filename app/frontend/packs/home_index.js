window.addEventListener("turbolinks:load", () => {
  // I bet this could be done with boostrap events instead
  document.addEventListener('click', (event) => {
    let buttonState = event.target.dataset.toggled;

    if (!buttonState) {
      return;
    }

    console.log(buttonState)
    if (buttonState === 'false') {
      event.target.classList.remove("btn-outline-info");
      event.target.classList.add("btn-info");
      event.target.dataset.toggled = 'true';
    } else if (buttonState === 'true') {
      event.target.classList.remove("btn-info");
      event.target.classList.add("btn-outline-info");
      event.target.dataset.toggled = 'false';
    }
  });
});