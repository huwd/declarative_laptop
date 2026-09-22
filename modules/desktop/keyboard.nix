_: {
  # ── Key remapping ────────────────────────────────────────────────────────────
  # keyd remaps at the input layer, below GNOME, so it applies everywhere:
  # every app, the GDM login screen, TTYs, and any keyboard plugged in.

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main.capslock = "esc";
    };
  };

  # keyd emits keys from a virtual keyboard that libinput would otherwise treat
  # as external, breaking "disable touchpad while typing". Mark it internal.
  environment.etc."libinput/local-overrides.quirks".text = ''
    [Serial Keyboards]
    MatchUdevType=keyboard
    MatchName=keyd virtual keyboard
    AttrKeyboardIntegration=internal
  '';
}
