_: {
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Huw Diprose";
        email = "mail@huwdiprose.co.uk";
      };

      alias = {
        l = "log --graph --date=short";
      };

      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
    };

    # Sign commits and tags with the SSH key held in Bitwarden
    signing = {
      format = "ssh";
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = true;
    };
  };

  # Keys trusted to sign as me; used by `git log --show-signature`
  home.file.".ssh/allowed_signers".text = ''
    mail@huwdiprose.co.uk ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINwayHfahI9FrcOSEYCp1WX6GcsLVEhTQojvlqqELSiA
  '';
}
