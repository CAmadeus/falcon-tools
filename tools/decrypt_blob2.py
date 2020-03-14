#!/usr/bin/env python3

import errno
import os
import struct
import sys
import binascii

from Crypto.Cipher import AES
from Crypto.Hash import CMAC


with open("blob2_aes_key.bin", 'rb') as f:
    blob2_aes_key = f.read()
    print(binascii.hexlify(blob2_aes_key))

blob2_aes_iv = b'00000000000000000000000000000000'


print(type(blob2_aes_iv))
with open("blob2.bin", "rb") as f:
    encrypted_blob2 = f.read()

aes_egnine = AES.new(blob2_aes_key, AES.MODE_ECB)

plain_blob2 = aes_egnine.decrypt(encrypted_blob2)

with open("blob2_plain.bin", "wb") as f:
    f.write(plain_blob2)