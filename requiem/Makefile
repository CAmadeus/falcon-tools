NAME := main
PACKED_NAME := tsec_fw

REQUIEM_DIR = .
LIBFAUCON_DIR = ../libfaucon
TOOLS_DIR = ../tools

LIBFAUCON_SOURCES = $(wildcard LIBFAUCON_DIR/*.asm)

# The key data to fake-sign the Heavy Secure mode portion of the payload.
# Provide real data here.
KEY  ?= 00000000000000000000000000000000
SEED ?= 00000000000000000000000000000000

all: $(PACKED_NAME).h

$(NAME)_fw_real.asm: $(NAME).asm $(LIBFAUCON_SOURCES)
	@m4 -I $(LIBFAUCON_DIR) -I $(REQUIEM_DIR) $(NAME).asm > $@

$(NAME)_fw.bin: $(NAME)_fw_real.asm
	@envyas -m falcon -V fuc5 -F crypt $? -i -o $@

$(PACKED_NAME).bin: $(NAME)_fw.bin
	@$(TOOLS_DIR)/sign_hs_payload.py $? $@ $(KEY) $(SEED)

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
