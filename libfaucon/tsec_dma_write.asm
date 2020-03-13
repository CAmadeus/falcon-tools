pushdef(`addr', `$r10')
pushdef(`value', `$r11')

tsec_dma_write:
    mpush $r1
    mov b32 $r0 addr
    mov b32 $r1 value
    lcall #tsec_wait_dma
    mov $r9 0x1
    bra b32 addr 0x0 ne #tsec_dma_write_end

    mov $r9 0x1c100
    iowr I[$r9] $r0

    add b32 $r9 $r9 0x100
    iowr I[$r9] $r1

    mov $r15 0x800000f2
    sub b32 $r9 $r9 0x200
    iowr I[$r9] $r15

    lcall #tsec_wait_dma

    cmp b32 $r10 0x0
    xbit $r9 $flags z
    xor $r9 0x1

    tsec_dma_write_end:
        mov b32 $r10 $r9
        mpopret $r1

popdef(`value')
popdef(`addr')