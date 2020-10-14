#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
from binascii import unhexlify

from Crypto.Cipher import AES


def decrypt_blob2(blob2_path, output_path, key, iv=None):
    with open(blob2_path, "rb") as f:
        blob2 = f.read()

    if not iv:
        iv = unhexlify("00000000000000000000000000000000")
    blob2_dec = AES.new(key, AES.MODE_CBC, iv).decrypt(blob2)

    with open(output_path, "wb") as f:
        f.write(blob2_dec)


if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) < 3:
        print("Usage: blob2_path output_path key [iv]")
    else:
        decrypt_blob2(*args)
