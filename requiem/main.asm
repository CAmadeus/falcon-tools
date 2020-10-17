.section #ns_code

// Load in the exception vector for HS authentication failure.
mov $r13 #sigauth_tv
mov $tv $r13

// Set up the Falcon stack pointer.
mov $r13 #FALCON_HWCFG
iord $r13 I[$r13]
shr b32 $r13 0x9
and $r13 0x1FF
shl b32 $r13 0x8
mov $sp $r13
lcall #main
exit

main:
    mov $r15 -0x10
    add $sp -0x11C

    mpush $r8

    // Allocate memory for the Key Data table.
    mov $r9 $sp
    add b32 $r9 $r9 0xC4
    and $r5 $r9 $r15

    // Copy Key Data into DMEM.
    mov b32 $r10 $r5
    mov $r11 #KEY_TABLE_START
    mov $r12 #KEY_TABLE_SIZE
    lcall #memcpy_i2d

    // Remap the signed microcode portion to its expected virtual address.
    clear b32 $r10
    mov $r11 #HS_PAYLOAD_PHYS_ADDR
    ld b32 $r12 D[$r5 + 0x20]
    lcall #memcpy_i2d
    mov b32 $r11 $r10
    mov $r10 #HS_PAYLOAD_START
    mov b32 $r13 $r10
    mov $r14 0x1
    lcall #memcpy_d2i

    // Load in the $sec details for Heavy Secure mode authentication.
    ld b32 $r9 D[$r5 + 0x20]
    shl b32 $r9 0x10
    mov $r15 #HS_PAYLOAD_START
    shr b32 $r15 0x8
    or $r9 $r15
    mov $cauth $r9

    // Transfer the MAC of the secure payload into crypto register 6.
    clear b32 $r7
    mov b32 $r8 $r5
    sethi $r8 0x60000
    cxset 0x2
    xdst $r7 $r8
    xdwait

    // Transfer the seed for the fake-signing key into crypto register 7.
    clear b32 $r7
    add b32 $r8 $r5 0x10
    sethi $r8 0x70000
    cxset 0x2
    xdst $r7 $r8
    xdwait

    // Jump to Heavy Secure Mode!
    lcall #HS_PAYLOAD_START

    mpopaddret $r8 0x11C

sigauth_tv:
    mov $r8 $cauth
    mov $r9 #FALCON_MAILBOX1
    iowr I[$r9] $r8

    iret

include(`mmio.asm')
include(`memcpy_i2d.asm')
include(`memcpy_d2i.asm')

.align 0x100
.section #ns_data 0x200
.equ #KEY_TABLE_SIZE 0x7C

KEY_TABLE_START:
HS_PAYLOAD_MAC:     .skip 0x10
HS_PAYLOAD_SEED:    .skip 0x10
HS_PAYLOAD_SIZE:    .b32 0x00000000

.align 0x100
HS_PAYLOAD_PHYS_ADDR:
.section #hs_code 0x200
.equ #HS_PAYLOAD_START 0x200

hs_main:
    mov $r11 #FALCON_MAILBOX1
    mov $r12 0xBADC0DED
    iowr I[$r11] $r12

    // Clear the HS signature and return back to NS mode.
    csigclr
    ret

.align 0x100
