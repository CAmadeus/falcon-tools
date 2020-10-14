#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from pathlib import Path
from struct import unpack
import sys


def extract_tsec_fw(package1_path):
    package1_path = Path(package1_path)
    output_path = Path("tsec_fw.bin")

    with open(package1_path, "rb") as f:
        package1 = f.read()

    hovi_common_seed_position = package1.find(b"HOVI_COMMON_01\x00\x00")
    if hovi_common_seed_position == -1:
        raise RuntimeError("Malformed Package1 binary!")

    # Parse the Key Data table.
    key_data_start = hovi_common_seed_position - 0x60
    key_data_end = key_data_start + 0x100
    (
        boot_size,
        keygenldr_size,
        keygen_size,
        securebootldr_size,
        secureboot_size
    ) = unpack("16s16s16s16s16s16s16sIIIII124x", package1[key_data_start:key_data_end])[7:]

    tsec_fw_size = boot_size + 0x100 + keygenldr_size + keygen_size + securebootldr_size + secureboot_size
    tsec_fw_start = key_data_start - boot_size
    tsec_fw_end = tsec_fw_start + tsec_fw_size

    with open(output_path, 'wb') as f:
        f.write(package1[tsec_fw_start:tsec_fw_end])


if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) != 1:
        print("Usage: package1_path")
    else:
        extract_tsec_fw(args[0])
