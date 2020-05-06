#!/usr/bin/env python3

import errno
import os
import struct
import sys
import binascii


def mkdir(path):
    try:
        os.makedirs(path)
    except OSError as exc:
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

def save_to_file(file_path, data):
    with open(file_path, 'wb') as f:
        f.write(data)

def dump_blob(file_path, fw_data, blob_pos, blob_size):
    if blob_size == 0:
        return blob_pos
    print("Dumping %s from address 0x%x with size 0x%x" % (file_path, blob_pos, blob_size))
    save_to_file(file_path, fw_data[blob_pos : blob_pos + blob_size])
    return blob_pos + blob_size

def extract_fw(fw_path, output_path):
    mkdir(output_path)
    with open(fw_path, 'rb') as f:
        fw_data = f.read()
        hovi_common_seed_pos = fw_data.find(b'HOVI_COMMON_01\x00\x00')
        if hovi_common_seed_pos == -1:
            print("Cannot locate key data blob!")
            return
        key_blob_data_pos = hovi_common_seed_pos - 0x60
        key_data = fw_data[key_blob_data_pos : key_blob_data_pos + 0x100]

        save_to_file(output_path + "/key_data.bin", key_data)

        (debug_key,
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
         blob4_size,
        ) = struct.unpack("16s16s16s16s16s16s16sIIIII124x", key_data)

        print(key_blob_data_pos)

        blob_pos = 0

        blob_pos = dump_blob(output_path + "/blob0.bin", fw_data, blob_pos, blob0_size)
        # skip key data
        if blob_pos == key_blob_data_pos:
            blob_pos += 0x100
        blob_pos = dump_blob(output_path + "/blob1.bin", fw_data, blob_pos, blob1_size)
        blob_pos = dump_blob(output_path + "/blob2.bin", fw_data, blob_pos, blob2_size)
        blob_pos = dump_blob(output_path + "/blob4.bin", fw_data, blob_pos, blob4_size)
        blob_pos = dump_blob(output_path + "/blob3.bin", fw_data, blob_pos, blob3_size)

def main(args):
    if len(args) != 1:
        print("Usage: firwmare_directory")
    else:
        extract_fw(args[0] + "/tsec_fw.bin", args[0] + "/stages")

if __name__ == '__main__':
    main(sys.argv[1:])
