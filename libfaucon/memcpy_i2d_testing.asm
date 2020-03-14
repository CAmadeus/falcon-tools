// Temp variables
pushdef(`scratch_register', `$r9')
pushdef(`code_io_address', `$r11')
pushdef(`code_io_offset', `$r13')
pushdef(`position', `$r14')
pushdef(`temp_value', `$r15')

// Arguments
pushdef(`dest', `$r10')
pushdef(`src', `$r11')
pushdef(`size', `$r12')

memcpy_i2d_testing:
    mov scratch_register 0x2000000
    or src scratch_register
    mov scratch_register 0x6000
    iowr I[scratch_register] src
    clear b32 position
    mov code_io_address 0x6100
    clear b32 code_io_offset
    lbra #memcpy_i2d_testing_loop_compare
    memcpy_i2d_testing_copy_loop:
        iord temp_value I[code_io_address + code_io_offset * 0x4]
        shr b32 scratch_register position 0x2
        add b32 position position 0x4
        st b32 D[dest + scratch_register * 0x4] temp_value
    memcpy_i2d_testing_loop_compare:
        cmp b32 position size
        bra c #memcpy_i2d_testing_copy_loop

    mov $r10 $sp
    ld b32 $r15 D[$r10]
    // Result code
    //mov b32 $r15 $r10
    mov $r9 0x1100
    iowr I[$r9] $r15
    ret

popdef(`size')
popdef(`src')
popdef(`dest')

popdef(`scratch_register')
popdef(`dest')
popdef(`code_io_address')
popdef(`code_io_offset')
popdef(`temp_value')
