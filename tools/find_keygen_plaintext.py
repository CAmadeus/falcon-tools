#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from binascii import hexlify, unhexlify

from Crypto.Cipher import AES
from Crypto.Random import get_random_bytes

TSEC_DO_KEYGEN_RET = 0x929
FIRST_GADGET = 0x94D

CSECRET_00 = unhexlify("00000000000000000000000000000000")
KEYGEN_SIG = unhexlify("892A36228D49E0484D480CB0ACDA0234")


def hovi_common_01_enc(aes, block):
    kek = aes.encrypt(block)
    return AES.new(kek, AES.MODE_ECB).encrypt(KEYGEN_SIG)


def extract_addr(ciphertext):
    return int.from_bytes(ciphertext[0:4], "little") & 0xFFFF


def prepare_plaintext():
    block = bytearray(get_random_bytes(AES.block_size))
    block[0:4] = TSEC_DO_KEYGEN_RET.to_bytes(4, "little")

    return block


if __name__ == "__main__":
    aes = AES.new(CSECRET_00, AES.MODE_ECB)

    while True:
        block = prepare_plaintext()
        result = hovi_common_01_enc(aes, block)

        addr = extract_addr(result)
        if addr == FIRST_GADGET:
            print(f"Plaintext:  {hexlify(block)}\nCiphertext: {hexlify(result)}")
