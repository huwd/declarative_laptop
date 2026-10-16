# Operating the system

Commands for the day-to-day tasks that the other guides don't cover: rolling back, listing generations, and checking an earlier configuration for a vulnerability.
[The README](../README.md) covers applying and updating the configuration.

## Roll back

Every `just apply` creates a new generation.
If a change breaks something, switch back to the previous generation:

```bash
sudo nixos-rebuild switch --rollback
```

If the system doesn't boot, choose an earlier generation in the systemd-boot menu.
The boot menu keeps the 20 most recent generations (`configurationLimit` in `hosts/framework-13/configuration.nix`).

Rolling back restores the system configuration.
It doesn't undo changes to personal files or application data.

## List generations

```bash
nixos-rebuild list-generations
```

The garbage collector deletes generations older than 30 days each week.
See `nix.gc` in `hosts/framework-13/configuration.nix`.

## Check an earlier configuration for a vulnerability

The history of `flake.lock` records the dependency versions of every earlier configuration.
This answers "did CVE-YYYY-NNNNN affect the configuration on this date?", but it can't prove what was running on the laptop at the time.

Build the closure for an earlier commit without checking it out, then scan it with vulnix.
This is the scan that CI runs, including the mirror that replaces NVD's retired data feeds:

```bash
rev=<commit>
nix build "github:huwd/declarative_laptop/$rev#nixosConfigurations.framework-13.config.system.build.toplevel" \
  --no-link --print-out-paths > /tmp/old-closure
nix run nixpkgs#vulnix -- \
  --mirror https://vig-os.github.io/nvd-mirror/ \
  --closure "$(cat /tmp/old-closure)"
```

Leave out `--whitelist` to see every finding, including the ones that `vulnix.toml` accepts today.
[OPSEC.md](../OPSEC.md) explains what vulnix can and can't see.
