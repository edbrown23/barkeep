window.addEventListener('turbo:load', () => {
  const path = window.location.pathname.split('/')[1];

  const navbarLink = document.querySelector(`a[href='/${path}']`);
  if (navbarLink) {
    navbarLink.classList.add('active');
  }
});