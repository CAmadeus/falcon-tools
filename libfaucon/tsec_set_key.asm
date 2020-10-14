pushdef(`key_buffer', `$r10')
pushdef(`key_buffer_local', `$r0')

tsec_set_key:
    mpush $r0

    // Set DMA timeout
    mov $r15 0xFFF
    mov b32 key_buffer_local key_buffer
    mov $r9 0x1c300
    iowr I[$r9] $r15


    mov $r10 #SOR_NV_PDISP_SOR_DP_HDCP_BKSV_LSB
    ld b32 $r11 D[key_buffer_local]
    lcall #tsec_dma_write

    mov $r10 #SOR_NV_PDISP_SOR_TMDS_HDCP_BKSV_LSB
    ld b32 $r11 D[key_buffer_local + 0x4]
    lcall #tsec_dma_write

    mov $r10 #SOR_NV_PDISP_SOR_TMDS_HDCP_CN_MSB
    ld b32 $r11 D[key_buffer_local + 0x8]
    lcall #tsec_dma_write

    mov $r10 #SOR_NV_PDISP_SOR_TMDS_HDCP_CN_LSB
    ld b32 $r11 D[key_buffer_local + 0xC]
    lcall #tsec_dma_write
    mpopret $r0

popdef(`key_buffer_local')
popdef(`key_buffer')
