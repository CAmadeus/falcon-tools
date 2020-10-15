# Requiem

Requiem is an implementation of a Falcon bootrom exploit that allows for signing arbitrary code into Heavy Secure Mode
given that an attacker is capable of gaining ROP under a officially signed secure payload.

## Falcon Execution Modes

Starting from the Maxwell generation of NVIDIA GPUs, Falcon supports three different execution modes
at runtime which orchestrate the amount of privileges the Falcon has in accessing registers and memory.
These modes namely are:

* Non-secure mode (NS): The only possible mode that can be used without code that is cryptographically signed by NVIDIA.
Functionality is similar to pre-Maxwell Falcons, except that they can be further restricted in their capability to access
certain registers and/or do DMA.

* Light Secure mode (LS): Can be explicitly enabled from Heavy Secure mode context. This mode grants more privileges than
NS but fewer than HS and is mostly used for debugging purposes rather than in production code.

* Heavy Secure mode (HS): Granted by hardware after a successful MAC comparison upon jumping to a code block tagged as secure.
In this mode, the Falcon acts similar to a black box, as NVIDIA likes to say. Most of the internal state is inaccessible from
external sources (such as the host system) while the Falcon operates on the highest amount of privileges possible.

## How Authentication works

To authenticate microcode into Heavy Secure Mode, four certain conditions must be met:

* The microcode pages must be mapped to a virtual address previously chosen by the author

* The code pages in question must be marked secret

* The above information must be loaded into the [SEC register](https://switchbrew.org/wiki/TSEC#SEC)

* A valid MAC hash of the code to grant Heavy Secure privileges to must be loaded into crypto register 6

When the Program Counter then lands on the secret page that contains the signed microcode, the hardware will take the information
from [SEC](https://switchbrew.org/wiki/TSEC#SEC) and compute its own MAC over the code and checks it against the hash in `$c6`.
And if they match, Heavy Secure mode will be granted and the secure code will be executed.

## How Authentication really works

While the above procedure holds true, there's more to it in the details.

Upon hitting a code page marked secret, Falcon will jump into its internal ROM segment where roughly equivalent code will be executed:

```c
void grant_heavy_secure_mode_privileges() {
    uint32_t microcode_start = (*SEC & 0xFF) << 8;
    uint32_t microcode_size = ((*SEC >> 24) & 0xFF) << 8;

    if (microcode_start && microcode_size) {
        // Calculate a Davies Meyer MAC over the microcode into crypto register 5.
        calculate_davies_meyer_mac((volatile uint8_t *)microcode_start, microcode_size);

        // Load hardware secret 0x1 into crypto register 3.
        csecret($c3, 0x1);

        // Set $c3 as the key register for encryption/decryption operations.
        ckeyreg($c3);

        // Encrypt the seed in crypto register 7 itno crypto register 3.
        cenc($c3, $c7);

        // Set crypto register 3 as the key register for encryption/decryption again.
        ckeyreg($c3);

        // Encrypt the Davies Meyer MAC in crypto register 5 into crypto register 4.
        cenc($c4, $c5);

        // Compare the resulting MAC in crypto register 4 with the hash in crypto register 6.
        // Heavy Secure mode will be granted by FSMs in hardware afterwards if the check succeeds.
        csigcmp($c4, $c6);
    }

    raise_exception(OP_SECURE_FAULT);
}
```

The hardware uses the microcode, its length and its start address to generate a Davies Meyer MAC which
will then be encrypted with the Falcon signing key. For officially signed payloads, this will always be
`aes_encrypt(csecret(0x1), b"00000000000000000000000000000000")`.

However, that is only because officially signed payloads will set `$c7` to zero at the same time. In reality,
the seed which is stored in this register alongside the MAC in `$c6` will not be validated by the bootrom.

## Attack Scenario

This flaw can be abused through yet another mechanism of the Falcon crypto system: `csigenc`. It works by
encrypting the auth signature of the running HS microcode using an arbitrary crypto register as the key.
And on top of that, an ACL value of `0x13` will be set unconditionally on the register containing the result
of the encryption.

Generally, crypto registers which have bit 3 (Insecure Readable) set in their ACL value can be spilled into
DMEM with no further access restrictions from a secure context. And that is the case for an ACL value of 0x13!

By obtaining ROP under a secure payload, an attacker can abuse usages of `csigenc` to encrypt the auth signature
`s` of the running code using a crypto register that was filled with csecret `0x1` in advance. The result of that
encryption will be referred to as "fake signing key" `k` which can then be spilled into DMEM by continuing the ROP
chain.

On a computer, a signature `fs` for arbitrary microcode can be crafted by generating a Davies Meyer MAC over the code
and its virtual address and encrypting it with AES-128-ECB using `k`.

From a Non-Secure context, the fake-signed microcode can be mapped to the previously chosen virtual address with `$c6`
being filled with `fs` and `$c7` being filled with `s`. The bootrom will now calculate the signing key `k` that was
previously obtained through ROP under a real-signed payload and the signature check will pass.
