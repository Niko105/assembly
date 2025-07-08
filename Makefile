ASM_SOURCES := $(wildcard L-*.asm)
OBJ_DIR := build
OBJECTS := $(ASM_SOURCES:%.asm=$(OBJ_DIR)/%.o)
LIBRARY := libNiko.a

.PHONY: all clean

all: $(LIBRARY)

# Build the static library from all object files
$(LIBRARY): $(OBJECTS)
	ar rcs $@ $^

# Assemble each asm file into .o
$(OBJ_DIR)/%.o: %.asm | $(OBJ_DIR)
	nasm -f elf64 $< -o $@

# Ensure build directory exists
$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

clean:
	rm -rf $(OBJ_DIR) $(LIBRARY)


#made entirely with chatgpt, i do NOT know makefile