const projectNavLinks = Array.from(document.querySelectorAll('.top-links a[href^="#"]'));
const projectNavSections = projectNavLinks
  .map((link) => {
    const id = link.getAttribute("href").slice(1);
    const section = document.getElementById(id);
    if (!section) {
      return null;
    }
    return { id, link, section };
  })
  .filter(Boolean);

function setActiveProjectNav(activeId) {
  projectNavSections.forEach(({ id, link }) => {
    if (id === activeId) {
      link.setAttribute("aria-current", "location");
      return;
    }
    link.removeAttribute("aria-current");
  });
}

function getActiveProjectSection() {
  if (!projectNavSections.length) {
    return "";
  }
  let activeId = projectNavSections[0].id;
  projectNavSections.forEach(({ id, section }) => {
    if (section.getBoundingClientRect().top <= 140) {
      activeId = id;
    }
  });
  return activeId;
}

function updateProjectNavFromViewport() {
  const activeId = getActiveProjectSection();
  if (activeId) {
    setActiveProjectNav(activeId);
  }
}

function updateProjectNavFromHash() {
  if (!window.location.hash) {
    return false;
  }
  const activeId = window.location.hash.slice(1);
  if (!projectNavSections.some(({ id }) => id === activeId)) {
    return false;
  }
  setActiveProjectNav(activeId);
  return true;
}

projectNavLinks.forEach((link) => {
  link.addEventListener("click", () => {
    const activeId = link.getAttribute("href").slice(1);
    setActiveProjectNav(activeId);
  });
});

if (!updateProjectNavFromHash()) {
  updateProjectNavFromViewport();
}

window.addEventListener("scroll", updateProjectNavFromViewport, { passive: true });
window.addEventListener("hashchange", () => {
  if (!updateProjectNavFromHash()) {
    updateProjectNavFromViewport();
  }
});
