#!/usr/bin/env python3
"""Derive a deterministic age identity from an SSH-agent signature.

Signs a fixed challenge through the SSH agent (which may prompt for approval)
using a dedicated key, ~/.ssh/sops-age.pub by default. It turns the Ed25519
signature into a 32-byte seed with HKDF-SHA256, and prints it as an age
identity (AGE-SECRET-KEY-1...) on stdout.

The constants below are a compatibility contract: changing any of them changes
the derived key and locks every file encrypted to it. Bump the "v1" labels
instead of editing them.
"""

import base64
import hashlib
import hmac
import os
import subprocess
import sys

CHALLENGE = b"composer sops age identity v1\n"
NAMESPACE = "sops-age-v1"
HKDF_SALT = b"sops-age-derive"
HKDF_INFO = b"age-x25519-v1"
HRP = "age-secret-key-"

BECH32_CHARSET = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
BECH32_GENERATOR = (0x3B6A57B2, 0x26508E6D, 0x1EA119FA, 0x3D4233DD, 0x2A1462B3)


def sign(pub_path):
    """Return the armoured SSHSIG for CHALLENGE, signed by the agent."""
    result = subprocess.run(
        ["ssh-keygen", "-Y", "sign", "-f", pub_path, "-n", NAMESPACE],
        input=CHALLENGE,
        stdout=subprocess.PIPE,
        check=True,
    )
    return result.stdout


def read_string(buf, offset):
    """Read one SSH length-prefixed string; return (value, next offset)."""
    length = int.from_bytes(buf[offset : offset + 4], "big")
    start = offset + 4
    return buf[start : start + length], start + length


def extract_signature(armoured):
    """Return the raw 64-byte Ed25519 signature from an armoured SSHSIG."""
    lines = armoured.decode().strip().splitlines()
    if lines[0] != "-----BEGIN SSH SIGNATURE-----" or lines[-1] != "-----END SSH SIGNATURE-----":
        raise ValueError("not an SSH signature")
    blob = base64.b64decode("".join(lines[1:-1]))
    if blob[:6] != b"SSHSIG" or int.from_bytes(blob[6:10], "big") != 1:
        raise ValueError("unsupported SSHSIG version")
    offset = 10
    for _ in range(4):  # public key, namespace, reserved, hash algorithm
        _, offset = read_string(blob, offset)
    sig_blob, _ = read_string(blob, offset)
    algorithm, offset = read_string(sig_blob, 0)
    raw, _ = read_string(sig_blob, offset)
    if algorithm != b"ssh-ed25519" or len(raw) != 64:
        raise ValueError("expected an ssh-ed25519 signature")
    return raw


def hkdf_sha256(ikm, salt, info, length=32):
    """HKDF (RFC 5869); a single block covers lengths up to 32 bytes."""
    if length > 32:
        raise ValueError("single-block HKDF only")
    prk = hmac.new(salt, ikm, hashlib.sha256).digest()
    return hmac.new(prk, info + b"\x01", hashlib.sha256).digest()[:length]


def bech32_polymod(values):
    chk = 1
    for value in values:
        top = chk >> 25
        chk = ((chk & 0x1FFFFFF) << 5) ^ value
        for i in range(5):
            if (top >> i) & 1:
                chk ^= BECH32_GENERATOR[i]
    return chk


def to_5bit(data):
    """Regroup bytes into 5-bit values, padding the last group with zeros."""
    acc = bits = 0
    out = []
    for byte in data:
        acc = (acc << 8) | byte
        bits += 8
        while bits >= 5:
            bits -= 5
            out.append((acc >> bits) & 31)
        acc &= (1 << bits) - 1
    if bits:
        out.append((acc << (5 - bits)) & 31)
    return out


def bech32_encode(hrp, data):
    values = to_5bit(data)
    expanded = [ord(c) >> 5 for c in hrp] + [0] + [ord(c) & 31 for c in hrp]
    mod = bech32_polymod(expanded + values + [0] * 6) ^ 1
    checksum = [(mod >> (5 * (5 - i))) & 31 for i in range(6)]
    return hrp + "1" + "".join(BECH32_CHARSET[d] for d in values + checksum)


def derive_identity(raw_signature):
    """Pure function: 64-byte signature in, age identity string out."""
    seed = hkdf_sha256(raw_signature, HKDF_SALT, HKDF_INFO)
    return bech32_encode(HRP, seed).upper()


def main():
    pub_path = (
        sys.argv[1]
        if len(sys.argv) > 1
        else os.environ.get("SOPS_AGE_DERIVE_PUB", os.path.expanduser("~/.ssh/sops-age.pub"))
    )
    try:
        print(derive_identity(extract_signature(sign(pub_path))))
    except (subprocess.CalledProcessError, ValueError) as err:
        sys.exit(f"sops-age-derive: {err}")


if __name__ == "__main__":
    main()
