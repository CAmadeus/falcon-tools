#!/usr/bin/env python3

import errno
import os
import struct
import sys
import binascii

from Crypto.Cipher import AES
from Crypto.Hash import CMAC

import pyaes

with open("blob0_auth_key.bin", 'rb') as f:
    blob0_auth_key = f.read()
    print(binascii.hexlify(blob0_auth_key))

blob0_auth_aes = pyaes.AES(blob0_auth_key)


with open("blob0.bin", "rb") as f:
    blob0 = f.read()

blob0_size = len(blob0)
print(blob0_size)

size_value = ((blob0_size & 0xff) << 8 | (blob0_size & 0xff00) >> 8) << 0x10 | ((blob0_size & 0xff0000) >> 0x10) << 8 | blob0_size >> 0x18

print(hex(size_value))

size_key = bytearray(0x10)

size_key[0xC:] = size_value.to_bytes(4, 'little')

cobj = CMAC.new(blob0_auth_key, ciphermod=AES)
cobj.update(size_key)
cobj.update(blob0)
print(cobj.hexdigest())