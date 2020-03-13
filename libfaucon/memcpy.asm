// Arguments
pushdef(`dest', `$r10')
pushdef(`src', `$r11')
pushdef(`size', `$r12')

memcpy:
    lbra #memcpy_loop_condition
    memcpy_loop:
        ld b32 $r15 D[src]
        add b32 src 0x4
        sub b32 size 0x4
        st b32 D[dest] $r15
        add b32 dest 0x4
    memcpy_loop_condition:
        bra b32 size 0x0 ne #memcpy_loop
        ret

popdef(`size')
popdef(`src')
popdef(`dest')