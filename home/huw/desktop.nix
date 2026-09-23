{ pkgs, ... }:
{
  # ── Dark mode ────────────────────────────────────────────────────────────────
  # color-scheme covers libadwaita/GTK4 apps (Geary's own dialogs, Nautilus…).
  # Stock GTK3 no longer ships a real "Adwaita-dark" — that name silently
  # falls back to light and half-themes anything with GTK3 chrome (e.g. Geary's
  # preferences window), so use adw-gtk3's dark variant for GTK3 instead.
  home.packages = [ pkgs.adw-gtk3 ];

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
    };
  };
}
