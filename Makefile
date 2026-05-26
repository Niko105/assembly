ASM_SOURCES := $(wildcard L-*.asm)
OBJ_DIR := build
OBJECTS := $(ASM_SOURCES:%.asm=$(OBJ_DIR)/%.o)
LIBRARY := libNiko.a

DEBUG ?= 0
ifeq ($(DEBUG), 1)
	NASM_FLAGS := -f elf64 -g -F dwarf
else
	NASM_FLAGS := -f elf64
endif

.PHONY: all clean

all: $(LIBRARY)

$(LIBRARY): $(OBJECTS)
	ar rcs $@ $^

$(OBJ_DIR)/%.o: %.asm | $(OBJ_DIR)
	nasm $(NASM_FLAGS) $< -o $@

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

clean:
	rm -rf $(OBJ_DIR) $(LIBRARY)

#make DEBUG=1 for the version with debug symbols
