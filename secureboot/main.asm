.section #ns_code

// Set up the Falcon stack pointer.
mov $r13 #FALCON_HWCFG
iord $r13 I[$r13]
shr b32 $r13 0x9
and $r13 0x1FF
shl b32 $r13 0x8
mov $sp $r13
lcall #main
exit

pushdef(`key_data_addr', `$r5')

main:
    mov $r15 -0x10
    add $sp -0x11C

    mpush $r8

    // Allocate memory for the Key Data table.
    mov $r9 $sp
    add b32 $r9 $r9 0xC4
    and key_data_addr $r9 $r15

    // Copy Key Data into DMEM.
    mov b32 $r10 key_data_addr
    mov $r11 #KEY_TABLE_START
    mov $r12 #KEY_TABLE_SIZE
    lcall #memcpy_i2d

    // Copy the signed microcode portion to DMEM.
    clear b32 $r10
    mov $r11 #HS_PAYLOAD_PHYS_ADDR
    ld b32 $r12 D[key_data_addr + 0x20]
    lcall #memcpy_i2d

    // Remap the signed microcode and tag it as secure.
    mov b32 $r11 $r10
    mov $r10 #HS_PAYLOAD_START
    mov b32 $r13 $r10
    mov $r14 0x1
    lcall #memcpy_d2i

    // Copy the encrypted Falcon OS image to DMEM.
    clear b32 $r10
    mov $r11 #FALCON_OS_START
    add b32 $r11 $r11 0x100
    ld b32 $r12 D[key_data_addr + 0x24]
    lcall #memcpy_i2d

    // Transfer the MAC of the secure payload into crypto register 6.
    clear b32 $r7
    mov b32 $r8 key_data_addr
    sethi $r8 0x60000
    cxset 0x2
    xdst $r7 $r8
    xdwait

    // Transfer the seed for the fake-signing key into crypto register 7.
    clear b32 $r7
    add b32 $r8 key_data_addr 0x10
    sethi $r8 0x70000
    cxset 0x2
    xdst $r7 $r8
    xdwait

    // Load in the cauth details for Heavy Secure mode authentication.
    ld b32 $r9 D[key_data_addr + 0x20]
    shl b32 $r9 0x10
    mov $r15 #HS_PAYLOAD_START
    shr b32 $r15 0x8
    or $r9 $r15
    mov $cauth $r9

    // Jump to Heavy Secure Mode!
    lcall #HS_PAYLOAD_START

    mpopaddret $r8 0x11C

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
    // Clear all interrupt bits.
    bclr $flags ie0
    bclr $flags ie1
    bclr $flags ie2

    // Clear all DMA overrides.
    cxset 0x80

    // Clear bit 19 in $cauth to not supress interrupts/exceptions.
    mov $r14 $cauth
    bclr $r14 19
    mov $cauth $r14

    // Set the target port for DMA transfers.
    mov $r14 0x0
    mov $xtargets $r14

    // Wait for all DMA code and data loads/stores to complete.
    xdwait
    xcwait

    // Decrypt the Falcon OS image into DMEM via DMA.
    clear b32 $r10
    ld b32 $r11 D[key_data_addr + 0x24]
    lcall #decrypt_cauth_payload

    // Transfer decrypted Falcon OS into external BPMP memory.
    clear b32 $r10
    ld b32 $r11 D[key_data_addr + 0x24]
    lcall #dma_transfer_to_bpmp_iram

    // Write the first plaintext word to mailbox 1 for comparison.
    mov $r11 #FALCON_MAILBOX1
    clear b32 $r12
    ld b32 $r12 D[$r12]
    iowr I[$r11] $r12

    // Clear the HS signature and return back to NS mode.
    csigclr
    ret

decrypt_cauth_payload:
    // Load in csecret 6 for decryptions.
    csecret $c5 0x6
    ckexp $c5 $c5
    ckeyreg $c5

    // Prepare a crypto script that decrypts one block at a time.
    cs0begin 0x3
        cxsin $c3
        cdec $c4 $c3
        cxsout $c4

__decrypt_cauth_payload_loop:
    // Prepare the transfer of a whole page into the crypto stream.
    mov b32 $r9 $r10
    sethi $r9 0x60000

    // Execute the crypto script 10 times (processes a whole page).
    cs0exec 0x10

    // Execute the DMA transfers into and out of the crypto stream.
    cxset 0x21
    xdst $r9 $r9
    cxset 0x22
    xdld $r9 $r9
    xdwait

    // Update state by advancing to the next page.
    add b32 $r10 $r10 0x100
    sub b32 $r11 0x100

    bra b32 $r11 0x0 ne #__decrypt_cauth_payload_loop
    ret


dma_transfer_to_bpmp_iram:
    // Prepare the external base address for DMA to BPMP.
    mov $r8 #FALCON_MAILBOX0
    iord $r9 I[$r8]
    add b32 $r9 $r9 $r10
    shr b32 $r9 0x8
    mov $xdbase $r9

    // Prepare DMA xfer arguments.
    clear b32 $r8
    mov b16 $r9 $r10
    sethi $r9 0x60000

    // Update state by advancing to the next page.
    add b32 $r10 $r10 0x100
    sub b32 $r11 0x100

    // Kick off the DMA code store operation.
    xdst $r8 $r9
    xdwait

    bra b32 $r11 0x0 ne #dma_transfer_to_bpmp_iram
    ret

popdef(`key_data_addr')

.align 0x100
FALCON_OS_START:
