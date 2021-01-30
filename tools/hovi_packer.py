#!/usr/bin/env python3

import errno
import os
import struct
import sys
from binascii import unhexlify

from Crypto.Cipher import AES

NULL_KEY = b"\x00" * AES.block_size


def align_up(value, size):
    return (value + (size - 1)) & -size


def generate_firmware(blob0_path, blob1_path, blob1_auth_hash, output_path):
    with open(blob0_path, "rb") as f:
        blob0 = f.read()
    with open(blob1_path, "rb") as f:
        blob1 = f.read()

    debug_key = NULL_KEY
    blob0_auth_hash = NULL_KEY
    blob2_auth_hash = NULL_KEY
    blob2_aes_iv = NULL_KEY
    hovi_eks_seed = b"HOVI_EKS_01\x00\x00\x00\x00\x00"
    hovi_common_seed = b"HOVI_COMMON_01\x00\x00"
    blob0_size_unaligned = len(blob0)
    blob1_size_unaligned = len(blob1)
    blob0_size = align_up(blob0_size_unaligned, 0x100)
    blob1_size = align_up(blob1_size_unaligned, 0x100)
    blob2_size = 0
    blob3_size = 0
    blob4_size = 0

    while blob0_size < 0x300:
        blob0_size += 0x100

    if blob0_size > 0x300:
        print(
            f"Warning: blob0_size > 0x300 (aligned size: 0x{blob0_size:X}, unaligned size: 0x{blob0_size_unaligned:X})")

    key_data = struct.pack("16s16s16s16s16s16s16sIIIII124x", debug_key,
                           blob0_auth_hash,
                           blob1_auth_hash,
                           blob2_auth_hash,
                           blob2_aes_iv,
                           hovi_eks_seed,
                           hovi_common_seed,
                           blob0_size,
                           blob1_size,
                           blob2_size,
                           blob3_size,
                           blob4_size)

    key_data_size_unaligned = len(key_data)
    key_data_size = align_up(key_data_size_unaligned, 0x100)

    with open(output_path, 'wb') as f:
        f.write(blob0)
        f.write(bytes(blob0_size - blob0_size_unaligned))

        key_data_position = f.tell()
        f.write(key_data)
        f.write(bytes(key_data_size - key_data_size_unaligned))

        f.write(blob1)
        f.write(bytes(blob1_size - blob1_size_unaligned))

        # Write keydata offset to configure it dynamically
        f.seek(0x1C, 0)
        f.write(struct.pack('I', key_data_position))


def main(args):
    if len(args) != 4:
        print("Usage: blob0_path blob1_path blob1_auth_hash output_path")
    else:
        generate_firmware(args[0], args[1], unhexlify(args[2]), args[3])


if __name__ == '__main__':
    main(sys.argv[1:])
