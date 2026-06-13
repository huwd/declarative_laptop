# agenix secret declarations
#
# Each entry names an encrypted file and lists the public keys that can decrypt it.
# The private keys never leave the machines — secrets are decrypted at activation.
#
# Setup:
#   1. After first boot, get the host key:
#        cat /etc/ssh/ssh_host_ed25519_key.pub
#   2. Get your personal key:
#        cat ~/.ssh/id_ed25519.pub
#   3. Fill in the let-bindings below and uncomment the secrets block
#   4. Encrypt a secret:
#        agenix -e secrets/github-token.age -i ~/.ssh/id_ed25519
#   5. Commit the .age file — the plaintext never touches the repo
#
# let
#   huw          = "ssh-ed25519 AAAA...";   # ~/.ssh/id_ed25519.pub
#   framework-13 = "ssh-ed25519 AAAA...";   # /etc/ssh/ssh_host_ed25519_key.pub
# in {
#   "github-token.age".publicKeys = [ huw framework-13 ];
# }
{ }
