const KEY = "tsuki-theme";
const root = document.documentElement;
const btn = document.querySelector("[data-theme-toggle]");

if (btn) {
  btn.hidden = false;
  btn.addEventListener("click", () => {
    const explicit = root.getAttribute("data-theme");
    const current = explicit
      || (matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
    const next = current === "dark" ? "light" : "dark";
    root.setAttribute("data-theme", next);
    try { localStorage.setItem(KEY, next); } catch {}
    btn.setAttribute("aria-pressed", String(next === "dark"));
  });

  const stored = (() => { try { return localStorage.getItem(KEY); } catch { return null; } })();
  const isDark = stored === "dark"
    || (!stored && matchMedia("(prefers-color-scheme: dark)").matches);
  btn.setAttribute("aria-pressed", String(isDark));
}
