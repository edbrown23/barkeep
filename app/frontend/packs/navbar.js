window.addEventListener('turbolinks:load', () => {
  const path = window.location.pathname;

  const navbarLink = document.querySelector(`a[href='${path}']`);
  navbarLink.classList.add('active');
});