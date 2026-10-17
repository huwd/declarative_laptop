"""Tests for sops-age-derive; none of them touch the SSH agent.

Run with: python3 -I -m unittest packages/sops-age-derive/test_sops_age_derive.py
"""

import importlib.util
import pathlib
import shutil
import subprocess
import unittest

_SCRIPT = pathlib.Path(__file__).with_name("sops-age-derive.py")
_spec = importlib.util.spec_from_file_location("sops_age_derive", _SCRIPT)
derive = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(derive)

# A fixed, non-secret stand-in for an Ed25519 signature.
FIXED_SIGNATURE = bytes(range(64))

# Golden value: the identity derived from FIXED_SIGNATURE under the v1 constants.
# If this test fails, the derivation changed and every file encrypted to the
# derived key would stop decrypting. Bump the "v1" labels instead of editing.
GOLDEN_IDENTITY = "AGE-SECRET-KEY-1FMU20GEGLDQ069CKSYC0P3LHS82LF8J24K09948AJFFD0RCV67PQU0E66S"


class GoldenVector(unittest.TestCase):
    def test_identity_is_stable(self):
        self.assertEqual(derive.derive_identity(FIXED_SIGNATURE), GOLDEN_IDENTITY)

    def test_identity_has_age_shape(self):
        identity = derive.derive_identity(FIXED_SIGNATURE)
        self.assertTrue(identity.startswith("AGE-SECRET-KEY-1"))
        self.assertEqual(identity, identity.upper())

    @unittest.skipUnless(shutil.which("age-keygen"), "age-keygen not on PATH")
    def test_age_accepts_identity(self):
        identity = derive.derive_identity(FIXED_SIGNATURE)
        result = subprocess.run(
            ["age-keygen", "-y"], input=identity + "\n", capture_output=True, text=True
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(result.stdout.startswith("age1"))


class Hkdf(unittest.TestCase):
    def test_rfc5869_case_1(self):
        # RFC 5869 appendix A.1, first 32 bytes of the output keying material.
        okm = derive.hkdf_sha256(
            ikm=bytes([0x0B] * 22),
            salt=bytes(range(0x00, 0x0D)),
            info=bytes(range(0xF0, 0xFA)),
        )
        self.assertEqual(
            okm.hex(),
            "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf",
        )

    @unittest.skipUnless(shutil.which("openssl"), "openssl not on PATH")
    def test_matches_openssl(self):
        result = subprocess.run(
            [
                "openssl", "kdf", "-keylen", "32", "-binary",
                "-kdfopt", "digest:SHA256",
                "-kdfopt", f"hexkey:{FIXED_SIGNATURE.hex()}",
                "-kdfopt", f"salt:{derive.HKDF_SALT.decode()}",
                "-kdfopt", f"info:{derive.HKDF_INFO.decode()}",
                "HKDF",
            ],
            capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout,
            derive.hkdf_sha256(FIXED_SIGNATURE, derive.HKDF_SALT, derive.HKDF_INFO),
        )


class Bech32(unittest.TestCase):
    def test_bip173_empty_payload(self):
        # BIP-173 lists "a12uel5l" as a valid bech32 string with no data.
        self.assertEqual(derive.bech32_encode("a", b""), "a12uel5l")


if __name__ == "__main__":
    unittest.main()
