#   simple-json, a simple json library
#   Copyright (C) 2022  Nate Choe <nate@natechoe.dev>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
