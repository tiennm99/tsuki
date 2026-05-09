const giscus = document.querySelector("[data-giscus]");
if (giscus) {
  const root = document.documentElement;
  const send = () => {
    const frame = document.querySelector("iframe.giscus-frame");
    if (!frame) return;
    const explicit = root.getAttribute("data-theme");
    const theme = explicit
      || (matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
    frame.contentWindow.postMessage(
      { giscus: { setConfig: { theme } } },
      "https://giscus.app"
    );
  };
  // Push current theme as soon as Giscus iframe is ready so first paint matches.
  // Self-remove after first valid Giscus message; later theme changes are caught by the MutationObserver below.
  let primed = false;
  const onFirstGiscusMessage = (e) => {
    if (primed) return;
    if (e.origin !== "https://giscus.app" || !e.data || !e.data.giscus) return;
    primed = true;
    window.removeEventListener("message", onFirstGiscusMessage);
    send();
  };
  window.addEventListener("message", onFirstGiscusMessage);
  new MutationObserver(send).observe(root, { attributes: true, attributeFilter: ["data-theme"] });
}
