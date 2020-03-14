NAME := main
PACKED_NAME := tsec_fw
STAGE1_PATH = ../payloads/hovi/1.0.0/keygenldr.bin
STAGE1_AUTH = 9c8b75d3df0bf06c95fc91c0761ef062

LIBFAUCON_DIR = ../libfaucon
TOOLS_DIR = ../tools

LIBFAUCON_SOURCES = $(wildcard LIBFAUCON_DIR/*.asm)

all: $(PACKED_NAME).h

$(NAME)_fw_real.asm: $(NAME).asm $(LIBFAUCON_SOURCES)
	@m4 -I $(LIBFAUCON_DIR) $(NAME).asm > $@

$(NAME)_fw.bin: $(NAME)_fw_real.asm
	@envyas -m falcon -V fuc5 -F crypt $? -i -o $@

$(PACKED_NAME).bin: $(NAME)_fw.bin
	@$(TOOLS_DIR)/hovi_packer.py $? $(STAGE1_PATH) $(STAGE1_AUTH) $@

$(NAME)_fw.h: $(NAME)_fw.bin
	@bin2c -o $@ $?

$(PACKED_NAME).h: $(PACKED_NAME).bin
	@bin2c -o $@ $?

print_dis: $(NAME)_fw.bin
	@envydis -i $? -m falcon -V fuc5 -F crypt -n

clean:
	@rm -f $(NAME)_fw.h $(NAME)_fw_real.asm $(NAME)_fw.bin $(PACKED_NAME).bin $(PACKED_NAME).h


re: clean all

.PHONY: $(NAME)_fw.h $(NAME)_fw_real.asm $(NAME)_fw.bin $(PACKED_NAME).bin $(PACKED_NAME).h

