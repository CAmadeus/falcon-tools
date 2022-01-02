#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from argparse import ArgumentParser, Namespace, FileType
import sys

def parse_arguments() -> Namespace:
    parser = ArgumentParser(description='Convert a binary to a C header.')
    parser.add_argument('binary_file', type=FileType('rb'), help='The path to the input binary to use')
    parser.add_argument('-o', '--output',  type=FileType('w', encoding='utf-8'), help='The path to the output C header', required=True)

    return parser.parse_args()

def main(arguments: Namespace) -> int:
    base_name = arguments.binary_file.name.replace('.', '_')
    binary_data = arguments.binary_file.read()
    binary_array_content = ', '.join([hex(x) for x in binary_data])

    binary_array_c_def = f"const char {base_name}[{len(binary_array_content)}] = {{ {binary_array_content} }};\n"
    binary_array_length_c_def = f"const int {base_name}_length = {len(binary_array_content)};\n"

    arguments.output.writelines([binary_array_c_def, binary_array_length_c_def])

    return 0

if __name__ == "__main__":
    args = parse_arguments()

    sys.exit(main(args))