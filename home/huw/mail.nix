_: {
  # ── Thunderbird ──────────────────────────────────────────────────────────────
  # Profile and privacy defaults are declared here. Accounts are added through
  # the UI, so no addresses or server details live in the repo.
  # Trialling Geary alongside this (installed via GNOME defaults, see
  # modules/desktop/gnome.nix) — remove this block if Geary wins out.

  programs.thunderbird = {
    enable = true;

    profiles.huw = {
      isDefault = true;

      settings = {
        # Don't load remote content: blocks tracking pixels and beacons
        "mailnews.message_display.disable_remote_image" = true;
        # Prefer plain text; fall back to simple HTML rather than original
        "mailnews.display.prefer_plaintext" = true;
        "mailnews.display.html_as" = 3;

        # No telemetry or crash report uploads
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "toolkit.telemetry.enabled" = false;
        "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;

        # Don't auto-collect recipients into the address book
        "mail.collect_email_address_outgoing" = false;
        # Skip the start page, which loads remote content
        "mailnews.start_page.enabled" = false;
      };
    };
  };
}
