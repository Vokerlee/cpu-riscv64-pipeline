CC = riscv64-unknown-linux-gnu
CFLAGS = -O0
LFLAGS = -nostdlib -Wl,-emain

EXAMPLES = test

OBJ_FILES = $(EXAMPLES:=.o)
OBJDUMP_FILES = $(EXAMPLES:=.obj)
EXE_FILES = $(EXAMPLES:=.out)

%.o: %.c
	$(CC)-gcc -c -o $@ $< $(CFLAGS)

%.obj: %.out
	$(CC)-objdump -d $< > $<.obj

%.out: %.o
	$(CC)-gcc $< -o $@ $(LFLAGS)

all: $(OBJ_FILES) $(EXE_FILES) $(OBJDUMP_FILES)

clean:
	$(RM) -f *.o *.obj *.out
