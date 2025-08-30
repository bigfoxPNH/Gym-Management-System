// Mobile Web Optimization
window.addEventListener("DOMContentLoaded", function () {
  // Disable pull-to-refresh on mobile
  document.body.style.overscrollBehavior = "none";

  // Prevent zoom on input focus (iOS Safari)
  const meta = document.createElement("meta");
  meta.name = "viewport";
  meta.content =
    "width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no";
  document.getElementsByTagName("head")[0].appendChild(meta);

  // Improve loading performance
  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.register("/flutter_service_worker.js");
  }

  // Mobile-specific optimizations
  document.addEventListener("touchstart", function () {}, true);
});

// Prevent iOS bounce effect
document.addEventListener(
  "touchmove",
  function (e) {
    if (e.target.tagName.toLowerCase() === "body") {
      e.preventDefault();
    }
  },
  false
);
