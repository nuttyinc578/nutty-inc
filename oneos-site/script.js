const nav = document.querySelector('.nav');
const toggle = document.querySelector('.mobile-toggle');

if (toggle && nav) {
  toggle.addEventListener('click', () => {
    nav.classList.toggle('open');
  });
}

document.addEventListener('click', (event) => {
  if (!nav || !toggle) return;
  const isNavClick = nav.contains(event.target) || toggle.contains(event.target);
  if (!isNavClick) {
    nav.classList.remove('open');
  }
});

const current = document.body.dataset.page;
if (current) {
  document.querySelectorAll('[data-nav]').forEach((link) => {
    if (link.dataset.nav === current) {
      link.classList.add('active');
    } else {
      link.classList.remove('active');
    }
  });
}
