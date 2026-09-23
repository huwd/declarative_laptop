_: {
  # ── Dark mode ────────────────────────────────────────────────────────────────
  # color-scheme covers libadwaita/GTK4 apps; gtk-theme covers GTK3 holdouts.
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
    };
  };
}
