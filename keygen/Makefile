NAME := main
PACKED_NAME := tsec_fw
STAGE2_PATH = ../payloads/hovi/1.0.0/Keygen.dec.bin
STAGE2_AUTH = 892A36228D49E0484D480CB0ACDA0234

KEYGEN_DIR = .
LIBFAUCON_DIR = ../libfaucon
TOOLS_DIR = ../tools

LIBFAUCON_SOURCES = $(wildcard LIBFAUCON_DIR/*.asm)

all: $(PACKED_NAME).h

$(NAME)_fw_real.asm: $(NAME).asm $(LIBFAUCON_SOURCES)
	@m4 -I $(LIBFAUCON_DIR) -I $(KEYGEN_DIR) $(NAME).asm > $@

$(NAME)_fw.bin: $(NAME)_fw_real.asm
	@envyas -m falcon -V fuc5 -F crypt $? -i -o $@

$(PACKED_NAME).bin: $(NAME)_fw.bin
	@$(TOOLS_DIR)/hovi_packer.py $? $(STAGE2_PATH) $(STAGE2_AUTH) $@

$(NAME)_fw.h: $(NAME)_fw.bin
	@$(TOOLS_DIR)/bin2c.py -o $@ $?

$(PACKED_NAME).h: $(PACKED_NAME).bin
	@$(TOOLS_DIR)/bin2c.py -o $@ $?

print_dis: $(NAME)_fw.bin
	@envydis -i $? -m falcon -V fuc5 -F crypt -n

clean:
	@rm -f $(NAME)_fw.h $(NAME)_fw_real.asm $(NAME)_fw.bin $(PACKED_NAME).bin $(PACKED_NAME).h


re: clean all

.PHONY: $(NAME)_fw.h $(NAME)_fw_real.asm $(NAME)_fw.bin $(PACKED_NAME).bin $(PACKED_NAME).h
