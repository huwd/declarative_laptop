let
  # Public half of the SSH key held in Bitwarden (no key files live in ~/.ssh)
  signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINwayHfahI9FrcOSEYCp1WX6GcsLVEhTQojvlqqELSiA";
in
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Huw Diprose";
        email = "mail@huwdiprose.co.uk";
      };

      alias = {
        l = "log --graph --date=short --pretty=format:'%C(blue)%ad%Creset %C(yellow)%h%C(green)%d%Creset %C(blue)%s %C(magenta) [%an]%Creset'";
        "recent-branches" =
          "!git for-each-ref --count=15 --sort=-committerdate refs/heads/ --format='%(refname:short)'";
      };

      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";

      # Show base as well as ours/theirs in conflicts; delta renders it cleanly
      merge.conflictStyle = "zdiff3";

      # Remember conflict resolutions so they auto-apply if the same conflict recurs
      rerere.enabled = true;

      init.defaultBranch = "main";

      # Better diffs on moved/rearranged code than the default "myers" algorithm
      diff.algorithm = "patience";

      color = {
        ui = true;
        branch = {
          current = "yellow reverse";
          local = "yellow";
          remote = "green";
        };
        diff = {
          meta = "yellow bold";
          frag = "magenta bold";
          old = "red";
          new = "green";
        };
      };
    };

    # Sign commits and tags with the SSH key held in Bitwarden
    signing = {
      format = "ssh";
      key = "key::${signingKey}";
      signByDefault = true;
    };

    # Global ignores, ported from huwd/dotfiles (dropped macOS/Windows-only entries)
    ignores = [
      # Tags: ctags, etags, gtags (GNU global), cscope
      "TAGS"
      "!TAGS/"
      "tags"
      "!tags/"
      ".tags"
      ".tags1"
      "gtags.files"
      "GTAGS"
      "GRTAGS"
      "GPATH"
      "cscope.files"
      "cscope.out"
      "cscope.in.out"
      "cscope.po.out"

      # Vim
      "[._]*.s[a-w][a-z]"
      "[._]s[a-w][a-z]"
      "*.un~"
      "Session.vim"
      ".netrwhist"
      "*~"

      # VS Code
      ".vscode/"
    ];
  };

  # delta — syntax-highlighted pager for diff, show, log -p and add -p.
  # Side-by-side on demand: git -c delta.side-by-side=true diff
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true; # n / N jump between files
      line-numbers = true;
      syntax-theme = "TwoDark"; # match bat
    };
  };

  # Keys trusted to sign as me; used by `git log --show-signature`
  home.file.".ssh/allowed_signers".text = ''
    mail@huwdiprose.co.uk ${signingKey}
  '';
}
