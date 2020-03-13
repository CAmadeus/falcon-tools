// Temp variables
pushdef(`scratch_register', `$r9')

// Arguments
pushdef(`phys_dest', `$r10')
pushdef(`src', `$r11')
pushdef(`size', `$r12')
pushdef(`virt_dest', `$r13')
pushdef(`is_secret', `$r14')

memcpy_d2i:
    mpush $r0
    mov b32 $r0 src
    mov b32 $r11 size
    mov b32 $r12 virt_dest

    bra b8 $r0 0x0 ne #memcpy_d2i_invalid_arguments
    bra b8 $r11 0x0 ne #memcpy_d2i_invalid_arguments
    bra b8 $r12 0x0 ne #memcpy_d2i_invalid_arguments

    bra b32 is_secret 0x0 e #memcpy_d2i_not_secret
    mov scratch_register 0x11000000
    lbra #memcpy_d2i_start_copy
    memcpy_d2i_not_secret:
        mov scratch_register 0x1000000
    memcpy_d2i_start_copy:
        or $r9 phys_dest $r9
        mov $r15 0x6000
        iowr I[$r15] scratch_register
        mov b32 $r10 $r0
        lcall #__memcpy_d2i_inner
        mpopret $r0
    memcpy_d2i_invalid_arguments:
        exit
        memcpy_d2i_invalid_arguments_exit_loop:
            lbra #memcpy_d2i_invalid_arguments_exit_loop

popdef(`scratch_register')


popdef(`is_secret')
popdef(`virt_dest')
popdef(`size')
popdef(`phys_dest')


// Arguments
pushdef(`src', `$r10')
pushdef(`size', `$r11')
pushdef(`virt_dest', `$r12')

__memcpy_d2i_inner:
    mpush $r3
    mov $r13 0x6100
    mov $r14 0x6200
    lbra #__memcpy_d2i_loop_compare
__memcpy_d2i_inner_loop_secure:
    and $r0 virt_dest 0xFF
    bra z #__memcpy_d2i_inner_handle_virt_page
__memcpy_d2i_inner_loop:
    ld b32 $r0 D[src + 0x0]
    ld b32 $r1 D[src + 0x4]
    ld b32 $r2 D[src + 0x8]
    ld b32 $r3 D[src + 0xc]
    iowr I[$r13] $r0
    iowr I[$r13] $r1
    iowr I[$r13] $r2
    iowr I[$r13] $r3
    add b32 src 0x10
    sub b32 size 0x10
    add b32 virt_dest 0x10
__memcpy_d2i_loop_compare:
    bra b32 size 0x0 ne #__memcpy_d2i_inner_loop_secure
    mpopret $r3
__memcpy_d2i_inner_handle_virt_page:
    shr b32 $r0 virt_dest 0x8
    iowr I[$r14] $r0
    lbra #__memcpy_d2i_inner_loop


popdef(`virt_dest')
popdef(`size')
popdef(`src')
