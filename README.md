# falcon-tools

A toolbox for researching and hacking NVIDIA Falcon microprocessors used in TSEC engines on the Tegra X1.

The generic goal is to provide a collection of tools, exploits and code for demystifying the Falcon and
its cryptographic functionality to ease up research for people interested in the cryptosystem and in
reversing Nintendo's TSEC firmwares in Package1 and nvservices.

## Components

* [keygenldr](./keygenldr): A set of ROP chains for obtaining keys used by the KeygenLdr payload of the
Nintendo Switch TSEC firmware.

* [keygen](./keygen): A ROP chain targetting the Keygen stage of the TSEC firmware, which generates and
dumps a "fake signing" key

* [secureboot](./secureboot): A payload that decrypts the SecureBoot stage into memory using csecret 6,
allowing the user to obtain the plaintext of this stage

* [requiem](./requiem): A template for writing fake-signed Falcon microcode that runs a payload in
Heavy Secure mode; Useful for research and reversing

* [libfaucon](./libfaucon): A standard library for Falcon firmware development; Features implementations
of commonly used functions and definitions for MMIO registers

* [tools](./tools): Helper scripts for working with TSEC firmware blobs

## Usage

With the components out of the way, the order for using these ROP chains on hardware is as following:

Prerequisites: Install Python 3.6+ on your machine and get the `PyCryptodome` package via `pip`. Additionally,
you will need [envytools](https://github.com/envytools/envytools), `make`, `m4` and `bin2c` on your system.

1. Clone this repository and set up an environment for controlling a TSEC engine, e.g. through RCM payloads
on the Nintendo Switch. We're providing a fork of hekate, with GUI adapted to launch a TSEC payload
[right here](https://github.com/CAmadeus/faucon_launcher).

2. Get a dump of Package1, preferably from firmware **8.1.0** or **1.0.0**. You don't need to bring the
keys to decrypt the PK11 blob, the TSEC firmware is bundled in its plaintext for Package1ldr.

3. Invoke the [`hovi_fw_extractor.py`](./tools/hovi_fw_extractor.py) script with the path to your dump of
Package1 as a command line argument. The script extracts the TSEC firmware and creates a new `tsec_fw.bin`
binary in the same directory.

4. Invoke the [`hovi_stage_extractor.py`](./tools/hovi_stage_extractor.py) script with the path to the
**directory** containing the previously extracted `tsec_fw.bin` blob, not the path to the blob itself
as a command line argument. It will output a folder `stages` in that directory which contains all the
individual stages the TSEC firmware is composed of.

5. Copy `stages/KeygenLdr.bin` and `stages/Keygen.bin` from the previous step to `payloads/hovi/1.0.0`.
These payloads have never changed since day 1, that's why the Package1 version does not matter here.
Additionally, if on 8.1.0, copy `SecureBoot.bin` to `payloads/hovi/8.1.0`. 8.1.0 or newer is recommended
because this is the version where Nintendo officially deprecated the TSEC firmware. The payload is
unlikely to change ever again in the future (and so are the keys it generates).

6. Build the [`keygenldr`](./keygenldr) ROP chain using `make` and select the ROP chain you want to use
(`code_sig_01`, `code_enc_01`) in the Makefile. Depending on the ROP chain, a different key will be copied
to the SOR1 HDCP registers.

* `CODE_SIG_01` is used for AES-CMAC of the Boot stage in KeygenLdr. If you want to launch KeygenLdr with
a customized Boot stage, use [`tools/hovi_keygenldr_auth_boot.py`](./tools/hovi_keygenldr_auth_boot.py) to
sign your own blob using this key.

* `CODE_ENC_01` is used for decrypting the following Keygen stage using AES-CBC. Dump this key and use
[`tools/decrypt_blob2.py`](./tools/decrypt_blob2.py) to decrypt `payloads/hovi/1.0.0/Keygen.bin` to
`payloads/hovi/1.0.0/Keygen.dec.bin` **before advancing to the next step**.

7. Build the [`keygen`](./keygen) ROP chain using `make` and run it. It will exploit the previously
decrypted `Keygen.dec.bin` blob on hardware to spill `aes_encrypt(csecret(0x1), "892A36228D49E0484D480CB0ACDA0234")`
to the SOR1 HDCP registers. This key can be used as a fake-signing key for the following steps.

8. Refer to [this writeup](./requiem/README.md) to learn about fake-signing and what exactly you did just
dump with the Keygen ROP chain. Since this effectively gives you the possibility to sign your own code
into Heavy Secure mode, there are plenty of uses for this:

* Reverse engineering the behavior of certain crypto commands

* Dumping all the ACL 0x13 csecrets to SOR1 HDCP registers where they can be read out

* Decrypting payloads encrypted with csecret 6 (such as the final SecureBoot stage), which is usually done
by the BootROM during authentication through setting a special bit in a register.

9. Build the [`secureboot`](./secureboot) payload using `make` and run it. After that, dump the TSEC DMEM
(see [faucon_launcher](https://github.com/CAmadeus/faucon_launcher) for a reference implementation through
button input) to SD card and extract the decrypted blob starting from address 0. It can then be analyzed
using [ghidra_falcon](https://github.com/Thog/ghidra_falcon) or another disassembler.

With all these steps combined, one can obtain the plaintexts of a few specific hardware secrets along with
the plaintext blobs of each stage of the TSEC firmware for research and analysis, which makes this obscure
black box more accessible towards other people without a background in Falcon security.

## Credits

The exploits and tools collected in this repository were developed by [**Thog**](https://github.com/Thog)
and [**vbe0201**](https://github.com/vbe0201).

We credit the following people for their great contributions to this project:

* [Elise](https://github.com/EliseZeroTwo) for help and advise in the early stages

* [SciresM](https://github.com/SciresM) and [hexkyz](https://github.com/hexkyz) for being very helpful and
informative throughout our research

## Licensing

This software is licensed under the terms of the GNU GPLv2.

See the [LICENSE](./LICENSE) file for details.
