const toc = document.querySelector(".toc");
if (toc) {
  const links = new Map();
  for (const a of toc.querySelectorAll('a[href^="#"]')) {
    const id = decodeURIComponent(a.getAttribute("href").slice(1));
    if (id) links.set(id, a);
  }

  const headings = document.querySelectorAll(".post-content :is(h2, h3, h4)[id]");
  if (headings.length && links.size) {
    const visible = new Set();
    const setActive = (id) => {
      for (const a of toc.querySelectorAll('a[aria-current="true"]')) a.removeAttribute("aria-current");
      const link = links.get(id);
      if (link) link.setAttribute("aria-current", "true");
    };

    const observer = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) visible.add(entry.target.id);
        else visible.delete(entry.target.id);
      }
      if (visible.size) {
        for (const h of headings) {
          if (visible.has(h.id)) { setActive(h.id); break; }
        }
      }
    }, { rootMargin: "-15% 0px -70% 0px", threshold: 0 });

    for (const h of headings) observer.observe(h);
  }
}
