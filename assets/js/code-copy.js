const COPY = "Sao chép";
const COPIED = "Đã chép";
const FAILED = "Lỗi";

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
    } catch {
      btn.textContent = FAILED;
    }
    setTimeout(() => { btn.textContent = COPY; }, 1500);
  });
}
