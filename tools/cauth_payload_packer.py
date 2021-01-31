#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from binascii import hexlify, unhexlify
from struct import pack, unpack
import sys

from Crypto.Cipher import AES


def sxor(x, y):
    return bytearray(a ^ b for a, b in zip(x, y))


def align_up(value, size):
    return (value + (size - 1)) & -size


def append_padding(blob, align):
    expected_len = align_up(len(blob), align)
    return blob + b"\x00" * (expected_len - len(blob))


def craft_key_table(auth_hash, seed, payload_len, cauth_payload_len):
    print(hexlify(auth_hash).decode("ascii"))
    return append_padding(
        pack("16s16sII", auth_hash, seed, payload_len, cauth_payload_len),
        0x100
    )


def calculate_davies_meyer_mac(data, address):
    ciphertext = bytearray(AES.block_size)

    for i in range(0, len(data), 0x100):
        blocks = data[i:i + 0x100] + pack("<IIII", address, 0, 0, 0)
        for k in range(0, len(blocks), AES.block_size):
            aes = AES.new(blocks[k:k + AES.block_size], AES.MODE_ECB)
            ciphertext = sxor(aes.encrypt(ciphertext), ciphertext)

        address += 0x100

    return ciphertext


def generate_hs_auth_hash(key, data, address):
    assert len(data) % 0x100 == 0

    mac = calculate_davies_meyer_mac(data, address)
    return AES.new(key, AES.MODE_ECB).encrypt(mac)


def extract_falcon_os(image):
    falcon_header = image[:0x18]
    falcon_header_size = int.from_bytes(falcon_header[0xC:0x10], "little")
    falcon_os_header = image[falcon_header_size:falcon_header_size + 0x10]

    falcon_code_header_size = int.from_bytes(
        falcon_header[0x10:0x14], "little")
    falcon_os_size = int.from_bytes(falcon_os_header[0x4:0x8], "little")

    falcon_os_start = falcon_code_header_size + 0x100
    falcon_os_end = falcon_os_start + (falcon_os_size - 0x100)
    return image[falcon_os_start:falcon_os_end]


def main(firmware, cauth_payload, output, key, seed):
    with open(firmware, "rb") as f:
        fw = f.read()
    with open(cauth_payload, "rb") as f:
        flcn = f.read()

    ns_payload = fw[:0x200]
    hs_payload = fw[0x300:]

    # Extract the Falcon OS image out of the cauth blob.
    falcon_os = extract_falcon_os(flcn)

    # Sign the Heavy Secure Mode payload.
    auth_hash = generate_hs_auth_hash(key, hs_payload, 0x200)
    key_table = craft_key_table(auth_hash, seed, len(hs_payload), len(falcon_os))
    assert len(key_table) == 0x100

    # Write the final firmware blob.
    with open(output, "wb") as f:
        f.write(ns_payload)
        f.write(key_table)
        f.write(hs_payload)
        f.write(falcon_os)


if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) != 5:
        print("Usage: firmware_path falcon_os_path output_path key seed")
    else:
        main(
            args[0],
            args[1],
            args[2],
            unhexlify(args[3]),
            unhexlify(args[4])
        )
