"use strict";

(function () {
  var dialogElement = document.getElementById("timeout_dialog");

  if (!dialogElement) return;

  var continueButtonElement = document.getElementById("continue_session");
  var warningTimeInMinutes = dialogElement.getAttribute("data-warning-in-minutes");
  var timeoutInMinutes = dialogElement.getAttribute("data-timeout-in-minutes");
  var refreshSessionPath = dialogElement.getAttribute("data-refresh-session-path");
  var timeoutInMilliseconds = (timeoutInMinutes - warningTimeInMinutes) * 60 * 1000;
  var timeoutPath = dialogElement.getAttribute("data-timeout-path");
  var dialog = new window.A11yDialog(dialogElement);

  continueButtonElement.onclick = function () {
    dialog.hide();
  };

  dialog.on("hide", function () {
    dialogElement.setAttribute("aria-hidden", "true");
    refreshSession();
  });

  function refreshSession() {
    Rails.ajax({
      url: refreshSessionPath,
      type: "get",
      success: function () {
        clearInterval(window.sessionTimeoutTimer);
        clearTimeout(window.sessionTimeout);
        window.sessionTimeoutTimer = setInterval(showTimeoutDialog, timeoutInMilliseconds);
      }
    });
  }

  function sessionTimedOut() {
    clearInterval(window.sessionTimeoutTimer);
    window.location = timeoutPath;
  }

  function showTimeoutDialog() {
    dialogElement.setAttribute("aria-hidden", "false");
    dialog.show();
    window.sessionTimeout = setTimeout(sessionTimedOut, warningTimeInMinutes * 60 * 1000);
  }

  window.sessionTimeoutTimer = setInterval(showTimeoutDialog, timeoutInMilliseconds);
})();
