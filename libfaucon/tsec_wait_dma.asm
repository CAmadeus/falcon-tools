tsec_wait_dma:
    mov $r15 0x1c000
    tsec_wait_dma_loop:
        iord $r9 I[$r15 + 0x0]
        extr $r10 $r9 0xc:0xe
        bra b32 $r10 0x1 e #tsec_wait_dma_loop
    ret