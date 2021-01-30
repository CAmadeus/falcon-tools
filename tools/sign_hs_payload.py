#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from binascii import hexlify, unhexlify
from struct import pack
import sys

from Crypto.Cipher import AES


def sxor(x, y):
    return bytearray(a ^ b for a, b in zip(x, y))


def align_up(value, size):
    return (value + (size - 1)) & -size


def append_padding(blob, align):
    expected_len = align_up(len(blob), align)
    return blob + b"\x00" * (expected_len - len(blob))


def craft_key_table(auth_hash, seed, payload_len):
    print(hexlify(auth_hash).decode('ascii'))
    return append_padding(pack("16s16sI", auth_hash, seed, payload_len), 0x100)


def calculate_davies_meyer_mac(data, address):
    ciphertext = bytearray(AES.block_size)

    for i in range(0, len(data), 0x100):
        blocks = data[i:i + 0x100] + pack("<IIII", address, 0, 0, 0)
        for k in range(0, len(blocks), AES.block_size):
            aes = AES.new(blocks[k:k + AES.block_size], AES.MODE_ECB)
            ciphertext = sxor(aes.encrypt(ciphertext), ciphertext)

        address += 0x100

    return ciphertext


def generate_hs_auth_signature(key, data, address):
    assert len(data) % 0x100 == 0

    mac = calculate_davies_meyer_mac(data, address)
    return AES.new(key, AES.MODE_ECB).encrypt(mac)


def main(firmware, output, key, seed):
    with open(firmware, "rb") as f:
        fw = f.read()

    ns_payload = fw[:0x200]
    hs_payload = fw[0x300:]

    # Sign the Heavy Secure Mode payload.
    auth_hash = generate_hs_auth_signature(key, hs_payload, 0x200)
    key_table = craft_key_table(auth_hash, seed, len(hs_payload))
    assert len(key_table) == 0x100

    # Overwrite the firmware data.
    with open(output, "wb") as f:
        f.write(ns_payload)
        f.write(key_table)
        f.write(hs_payload)


if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) != 4:
        print("Usage: firmware_path output_path key seed")
    else:
        main(args[0], args[1], unhexlify(args[2]), unhexlify(args[3]))
