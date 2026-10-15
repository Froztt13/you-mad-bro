/**
 * YouMadBro Documentation - Interactive Client Scripts
 */

document.addEventListener('DOMContentLoaded', () => {
  initMobileMenu();
  initCopyButtons();
  initSearch();
  initScrollSpy();
  initTabs();
});

// Mobile menu toggle with backdrop overlay
function initMobileMenu() {
  const toggleBtn = document.getElementById('menuToggle');
  const sidebar = document.getElementById('docsSidebar');
  const overlay = document.getElementById('sidebarOverlay');

  function openSidebar() {
    sidebar.classList.add('open');
    if (overlay) overlay.classList.add('active');
    document.body.style.overflow = window.innerWidth <= 992 ? 'hidden' : '';
  }

  function closeSidebar() {
    sidebar.classList.remove('open');
    if (overlay) overlay.classList.remove('active');
    document.body.style.overflow = '';
  }

  if (toggleBtn && sidebar) {
    toggleBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      if (sidebar.classList.contains('open')) {
        closeSidebar();
      } else {
        openSidebar();
      }
    });

    if (overlay) {
      overlay.addEventListener('click', () => {
        closeSidebar();
      });
    }

    // Close when clicking a nav link on mobile
    const links = sidebar.querySelectorAll('.nav-link');
    links.forEach(link => {
      link.addEventListener('click', () => {
        if (window.innerWidth <= 992) {
          closeSidebar();
        }
      });
    });

    // Close on resize if transitioning to desktop
    window.addEventListener('resize', () => {
      if (window.innerWidth > 992 && sidebar.classList.contains('open')) {
        closeSidebar();
      }
    });
  }
}

// Copy Code Buttons with Toast
function initCopyButtons() {
  const copyButtons = document.querySelectorAll('.copy-btn');
  const toast = document.getElementById('copyToast');

  copyButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const codeContainer = btn.closest('.code-container');
      const codeElement = codeContainer ? codeContainer.querySelector('code') : null;

      if (codeElement) {
        const textToCopy = codeElement.innerText;
        navigator.clipboard.writeText(textToCopy).then(() => {
          showToast('Copied to clipboard!');
          const originalText = btn.innerHTML;
          btn.innerHTML = '✓ Copied';
          setTimeout(() => {
            btn.innerHTML = originalText;
          }, 2000);
        }).catch(err => {
          console.error('Failed to copy text: ', err);
        });
      }
    });
  });
}

function showToast(message) {
  let toast = document.getElementById('copyToast');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'copyToast';
    toast.className = 'toast';
    document.body.appendChild(toast);
  }
  toast.textContent = message;
  toast.classList.add('show');
  setTimeout(() => {
    toast.classList.remove('show');
  }, 2200);
}

// Client-side Live Search
function initSearch() {
  const searchInput = document.getElementById('docsSearch');
  if (!searchInput) return;

  const sections = document.querySelectorAll('.doc-section');
  const navLinks = document.querySelectorAll('.nav-link');

  searchInput.addEventListener('input', (e) => {
    const query = e.target.value.toLowerCase().trim();

    if (query === '') {
      sections.forEach(sec => sec.style.display = 'block');
      navLinks.forEach(link => link.style.opacity = '1');
      return;
    }

    sections.forEach(sec => {
      const text = sec.innerText.toLowerCase();
      if (text.includes(query)) {
        sec.style.display = 'block';
      } else {
        sec.style.display = 'none';
      }
    });

    navLinks.forEach(link => {
      const targetId = link.getAttribute('href');
      if (targetId && targetId.startsWith('#')) {
        const targetSec = document.querySelector(targetId);
        if (targetSec && targetSec.style.display === 'none') {
          link.style.opacity = '0.35';
        } else {
          link.style.opacity = '1';
        }
      }
    });
  });
}

// ScrollSpy Active Link Update
function initScrollSpy() {
  const sections = document.querySelectorAll('.doc-section');
  const navLinks = document.querySelectorAll('.nav-link');

  window.addEventListener('scroll', () => {
    let currentId = '';
    const scrollPos = window.scrollY + 100;

    sections.forEach(sec => {
      const secTop = sec.offsetTop;
      const secHeight = sec.offsetHeight;
      if (scrollPos >= secTop && scrollPos < secTop + secHeight) {
        currentId = sec.getAttribute('id');
      }
    });

    if (currentId) {
      navLinks.forEach(link => {
        link.classList.remove('active');
        if (link.getAttribute('href') === `#${currentId}`) {
          link.classList.add('active');
        }
      });
    }
  });
}

// Interactive Tabs (e.g., Installation / OS tabs)
function initTabs() {
  const tabGroups = document.querySelectorAll('.tab-group');

  tabGroups.forEach(group => {
    const tabs = group.querySelectorAll('.tab-btn');
    const contents = group.querySelectorAll('.tab-content');

    tabs.forEach(tab => {
      tab.addEventListener('click', () => {
        const target = tab.getAttribute('data-tab');

        tabs.forEach(t => t.classList.remove('active'));
        contents.forEach(c => c.classList.remove('active'));

        tab.classList.add('active');
        const activeContent = group.querySelector(`.tab-content[data-content="${target}"]`);
        if (activeContent) {
          activeContent.classList.add('active');
        }
      });
    });
  });
}
