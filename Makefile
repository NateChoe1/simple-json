SRC = $(wildcard src/*.c)
AUTOSRC = work/json.tab.c work/json.yy.c
OBJ = $(subst .c,.o,$(subst src,work,$(SRC))) $(subst .c,.o,$(AUTOSRC))
LDFLAGS = -shared
CFLAGS := -O2 -pipe -Wall -Wpedantic -Wshadow
_CFLAGS = -fPIC -Isrc/
INSTALLDIR := /usr/sbin
HEADERDIR := /usr/include/
OUT = simple-json.so

build/$(OUT): $(OBJ)
	$(CC) $(OBJ) -o build/$(OUT) $(LDFLAGS)

work/%.o: src/%.c $(wildcard src/include/*.h)
	$(CC) -ansi $(_CFLAGS) $(CFLAGS) $< -c -o $@

work/%.o: work/%.c
	$(CC) $(_CFLAGS) $(CFLAGS) $< -c -o $@

work/json.tab.c: src/json.y
	$(YACC) -d -b work/json $<
work/json.yy.c: src/json.l
	$(LEX) -t $< > $@

install: build/$(OUT)
	cp build/$(OUT) $(INSTALLDIR)/$(OUT)
	cp -r src/simple-json $(HEADERDIR)/simple-json

uninstall: $(INSTALLDIR)/$(OUT)
	rm $(INSTALLDIR)/$(OUT)
	rm -r $(HEADERDIR)/simple-json
