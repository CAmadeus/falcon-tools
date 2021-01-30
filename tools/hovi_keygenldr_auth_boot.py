#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from binascii import hexlify, unhexlify
import sys

from Crypto.Cipher import AES


def sxor(x, y):
    return bytearray(a ^ b for a, b in zip(x, y))


def hswap(size):
    return (
        ((size & 0x000000FF) << 0x8
         | (size & 0x0000FF00) >> 0x8) << 0x10
        | ((size & 0x00FF0000) >> 0x10) << 0x8
        | (size & 0xFF000000) >> 0x18
    )


def encrypt_buffer(buffer, size, key):
    buffer[0xC:] = hswap(size).to_bytes(4, "little")
    return AES.new(key, AES.MODE_ECB).encrypt(buffer)


def generate_cmac(boot_path, key):
    with open(boot_path, "rb") as f:
        boot = f.read()

    # Craft the signature key to be used as the IV.
    sig_key = bytearray(AES.block_size)
    sig_key = encrypt_buffer(sig_key, len(boot), key)

    # Calculate the AES-CMAC hash over Boot code.
    ciphertext = sig_key
    for i in range(0, len(boot), AES.block_size):
        block_cipher = sxor(boot[i:i + AES.block_size], ciphertext)
        ciphertext = AES.new(key, AES.MODE_ECB).encrypt(block_cipher)

    return ciphertext


if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) != 2:
        print("Usage: boot_path key")
    else:
        cmac = generate_cmac(args[0], unhexlify(args[1]))
        print(f"Hash:  {hexlify(cmac).decode('ascii')}")
