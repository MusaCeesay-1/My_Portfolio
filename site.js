if ("scrollRestoration" in history) {
  history.scrollRestoration = "manual";
}

window.addEventListener("load", () => {
  if (!window.location.hash) {
    window.scrollTo(0, 0);
  }
});

const yearNode = document.getElementById("year");
const siteNav = document.querySelector(".nav");
const logoLink = document.querySelector(".logo");
const menuToggle = document.querySelector(".menu-toggle");
const siteMenu = document.getElementById("site-menu");
const mobileQuery = window.matchMedia("(max-width: 860px)");
const backToTopBtn = document.querySelector(".back-to-top");
const themeToggle = document.querySelector(".theme-toggle");
const themeStorageKey = "portfolio-theme";
let previousBodyOverflow = "";

if (yearNode) {
  yearNode.textContent = new Date().getFullYear();
}

function setTheme(theme) {
  document.documentElement.setAttribute("data-theme", theme);
  const isDark = theme === "dark";
  if (!themeToggle) {
    return;
  }
  themeToggle.setAttribute("aria-pressed", String(isDark));
  themeToggle.setAttribute("aria-label", isDark ? "Switch to light mode" : "Switch to dark mode");
  themeToggle.textContent = isDark ? "Light Mode" : "Dark Mode";
}

function initializeTheme() {
  const currentTheme = document.documentElement.getAttribute("data-theme");
  if (currentTheme === "light" || currentTheme === "dark") {
    setTheme(currentTheme);
    return;
  }
  const preferredTheme = window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  setTheme(preferredTheme);
}

function setMenuState(isOpen) {
  if (!siteMenu || !menuToggle) {
    return;
  }
  const wasOpen = siteMenu.classList.contains("is-open");
  siteMenu.classList.toggle("is-open", isOpen);
  siteMenu.setAttribute("aria-hidden", String(!isOpen));
  menuToggle.setAttribute("aria-expanded", String(isOpen));
  menuToggle.setAttribute("aria-label", isOpen ? "Close navigation menu" : "Open navigation menu");
  if (isOpen) {
    if (!wasOpen) {
      previousBodyOverflow = document.body.style.overflow;
    }
    document.body.style.overflow = "hidden";
    return;
  }
  if (wasOpen) {
    document.body.style.overflow = previousBodyOverflow || "";
  }
}

function closeMenu() {
  setMenuState(false);
}

function isMenuOpen() {
  return Boolean(siteMenu && siteMenu.classList.contains("is-open"));
}

function setActivePage() {
  if (!siteMenu) {
    return;
  }
  const currentPage = document.body.dataset.page;
  const navLinks = Array.from(siteMenu.querySelectorAll("a[data-page]"));
  navLinks.forEach((link) => {
    if (link.dataset.page === currentPage) {
      link.setAttribute("aria-current", "page");
      return;
    }
    link.removeAttribute("aria-current");
  });
}

if (menuToggle) {
  menuToggle.addEventListener("click", () => {
    setMenuState(!isMenuOpen());
  });
}

if (siteMenu) {
  Array.from(siteMenu.querySelectorAll("a")).forEach((link) => {
    link.addEventListener("click", () => {
      if (mobileQuery.matches) {
        closeMenu();
      }
    });
  });
}

window.addEventListener("resize", () => {
  if (!mobileQuery.matches) {
    closeMenu();
  }
});

document.addEventListener("click", (event) => {
  if (!siteNav || !mobileQuery.matches || !isMenuOpen()) {
    return;
  }
  if (!siteNav.contains(event.target)) {
    closeMenu();
  }
});

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && isMenuOpen()) {
    closeMenu();
  }
});

if (logoLink) {
  logoLink.addEventListener("click", () => {
    if (mobileQuery.matches) {
      closeMenu();
    }
  });
}

function toggleBackToTop() {
  if (!backToTopBtn) {
    return;
  }
  backToTopBtn.classList.toggle("is-visible", window.scrollY > 280);
}

if (backToTopBtn) {
  backToTopBtn.addEventListener("click", () => {
    window.scrollTo({ top: 0, behavior: "smooth" });
  });
}

if (themeToggle) {
  themeToggle.addEventListener("click", () => {
    const nextTheme = document.documentElement.getAttribute("data-theme") === "dark" ? "light" : "dark";
    setTheme(nextTheme);
    if (mobileQuery.matches && isMenuOpen()) {
      closeMenu();
    }
    try {
      localStorage.setItem(themeStorageKey, nextTheme);
    } catch (error) {
      // Ignore storage access issues and keep runtime theme state.
    }
  });
}

initializeTheme();
setMenuState(false);
setActivePage();
window.addEventListener("scroll", toggleBackToTop, { passive: true });
window.addEventListener("touchmove", toggleBackToTop, { passive: true });
window.addEventListener("wheel", toggleBackToTop, { passive: true });
toggleBackToTop();
