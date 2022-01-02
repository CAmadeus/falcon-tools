NAME := main
PACKED_NAME := tsec_fw
STAGE1_PATH = ../payloads/hovi/1.0.0/KeygenLdr.bin
STAGE1_AUTH = 9c8b75d3df0bf06c95fc91c0761ef062

KEYGENLDR_DIR = .
LIBFAUCON_DIR = ../libfaucon
TOOLS_DIR = ../tools

# Set this value to the name of the ROP chain that you want to use.
# Supported values: code_sig_01, code_enc_01
DESIRED_ROP_CHAIN = code_enc_01

LIBFAUCON_SOURCES = $(wildcard LIBFAUCON_DIR/*.asm)

all: $(PACKED_NAME).h

$(NAME)_fw_real.asm: $(NAME).asm $(LIBFAUCON_SOURCES)
	@cp $(DESIRED_ROP_CHAIN)_rop.asm rop.asm
	@m4 -I $(LIBFAUCON_DIR) -I $(KEYGENLDR_DIR) $(NAME).asm > $@

$(NAME)_fw.bin: $(NAME)_fw_real.asm
	@envyas -m falcon -V fuc5 -F crypt $? -i -o $@

$(PACKED_NAME).bin: $(NAME)_fw.bin
	@$(TOOLS_DIR)/hovi_packer.py $? $(STAGE1_PATH) $(STAGE1_AUTH) $@

$(NAME)_fw.h: $(NAME)_fw.bin
	@$(TOOLS_DIR)/bin2c.py -o $@ $?

$(PACKED_NAME).h: $(PACKED_NAME).bin
	@$(TOOLS_DIR)/bin2c.py -o $@ $?

print_dis: $(NAME)_fw.bin
	@envydis -i $? -m falcon -V fuc5 -F crypt -n

clean:
	@rm -f $(NAME)_fw.h $(NAME)_fw_real.asm rop.asm $(NAME)_fw.bin $(PACKED_NAME).bin $(PACKED_NAME).h


re: clean all

.PHONY: $(NAME)_fw.h $(NAME)_fw_real.asm rop.asm $(NAME)_fw.bin $(PACKED_NAME).bin $(PACKED_NAME).h
