const dataset = document.documentElement.dataset;
const COPY = dataset.copyCode || "Copy";
const COPIED = dataset.copiedCode || "Copied";

if (navigator.clipboard) {
  for (const pre of document.querySelectorAll("pre")) {
    const code = pre.querySelector("code");
    if (!code) continue;
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "code-copy";
    btn.setAttribute("aria-label", COPY);
    btn.textContent = COPY;
    pre.appendChild(btn);
    btn.addEventListener("click", async () => {
      try {
        await navigator.clipboard.writeText(code.innerText);
        btn.textContent = COPIED;
        btn.setAttribute("data-state", "copied");
      } catch {
        btn.textContent = COPY;
      }
      setTimeout(() => {
        btn.textContent = COPY;
        btn.removeAttribute("data-state");
      }, 1500);
    });
  }
}
