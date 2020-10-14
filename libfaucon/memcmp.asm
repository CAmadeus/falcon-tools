// Function arguments
pushdef(`ptr1', `$r10')
pushdef(`ptr2', `$r11')
pushdef(`size', `$r12')

// Locals
pushdef(`word1', `$r13')
pushdef(`word2', `$r14')
pushdef(`result', `$r10')

memcmp:
    lbra #memcmp_compare_loop_start

    memcmp_compare_loop:
        // Read two words from DMEM into registers and compare them.
        ld b32 word1 D[ptr1]
        ld b32 word2 D[ptr2]
        cmp b32 word1 word2
        bra ne #memcmp_ret_failure

        // Update the arguments and continue to compare data if there are still words left.
        add b32 ptr1 0x4
        add b32 ptr2 0x4
        sub b32 size 0x4
        memcmp_compare_loop_start:
            bra b32 size 0x0 ne #memcmp_compare_loop

    memcmp_ret_success:
        mov result 0x0
        ret

    memcmp_ret_failure:
        mov result 0x1
        ret

// End locals
popdef(`result')
popdef(`word2')
popdef(`word1')

// End function arguments
popdef(`size')
popdef(`ptr2')
popdef(`ptr1')
