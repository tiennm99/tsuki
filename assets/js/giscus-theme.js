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
  new MutationObserver(send).observe(root, { attributes: true, attributeFilter: ["data-theme"] });
}
