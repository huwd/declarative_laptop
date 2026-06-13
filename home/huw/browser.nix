{ pkgs, ... }:
{
  # ── Firefox ──────────────────────────────────────────────────────────────────
  # Primary browser. Extensions declared here are Nix-managed: versioned,
  # reproducible, and visible in git history. Any extension installed via the
  # browser UI instead will be flagged by the audit timer below.

  programs.firefox = {
    enable = true;

    profiles.huw = {
      isDefault = true;

      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        bitwarden           # password manager — pairs with bitwarden-desktop
        ublock-origin       # ad and tracker blocking
        vimium-ff           # vim keybindings in the browser
        multi-account-containers  # isolate sites to separate cookie jars
        privacy-badger      # tracker blocking (complementary to uBlock)
      ];

      # Enforce sensible privacy defaults via user.js
      # These override Firefox preferences declaratively
      settings = {
        "browser.startup.homepage" = "about:blank";
        "browser.newtabpage.enabled" = false;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "dom.security.https_only_mode" = true;
        "browser.download.useDownloadDir" = false; # always ask where to save
        "signon.rememberSignons" = false; # bitwarden handles this
        "browser.formfill.enable" = false;
        "extensions.pocket.enabled" = false;
      };
    };
  };

  # ── Extension audit ──────────────────────────────────────────────────────────
  # Detects extensions installed via the browser UI that are not Nix-managed.
  # Nix-managed extensions are symlinks pointing into /nix/store.
  # Manually installed extensions are real files or directories.
  # Results land in the journal: journalctl --user -u firefox-extension-audit

  systemd.user.services.firefox-extension-audit = {
    description = "Audit Firefox extensions for unmanaged installs";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "firefox-extension-audit" ''
        set -euo pipefail

        FOUND=0
        for ext_dir in "$HOME"/.mozilla/firefox/*/extensions; do
          [[ -d "$ext_dir" ]] || continue
          while IFS= read -r -d "" entry; do
            # Symlinks to the Nix store are managed — skip them
            if [[ -L "$entry" ]] && [[ "$(readlink -f "$entry")" == /nix/store/* ]]; then
              continue
            fi
            echo "UNMANAGED EXTENSION: $entry"
            FOUND=$((FOUND + 1))
          done < <(find "$ext_dir" -mindepth 1 -maxdepth 1 -print0)
        done

        if [[ $FOUND -gt 0 ]]; then
          echo "Found $FOUND unmanaged extension(s). Add them to home/huw/browser.nix or remove them."
          exit 1
        else
          echo "All Firefox extensions are Nix-managed."
        fi
      '';
    };
  };

  systemd.user.timers.firefox-extension-audit = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  # ── Chrome ───────────────────────────────────────────────────────────────────
  # Kept for site compatibility only. Zero extensions — the smaller the
  # footprint in Chrome the better given its weaker Home Manager support.
  # Already declared as a system package in modules/apps.nix.
}
