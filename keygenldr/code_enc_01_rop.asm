//
// A ROP chain designed to dump the "CODE_ENC_01" AES key that is used to
// decrypt the blob for the next stage, Keygen.
//
// gen_usr_key(1, 1);
// crypto_load(4, 0x990);
//

// We're going to copy the resulting key to this address in Falcon DMem.
.equ #ROP_KEY_BUFFER 0x990

.size 0x998
.section #rop_payload 0x998

// mpopret $r0
.b32 0x53D
.b32 0

// mov $r10 0x1
// ret
.b32 0x5B8

// $r10 = 1
// $r11 = 6100  ; Although Nintendo passes 1, any non-zero value will do.
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
// $r11 = 990
// -----------------
// lbra #crypto_load
.b32 0x5BD

// We have everything we need. Return to No Secure Mode code.
.b32 #ret2win
