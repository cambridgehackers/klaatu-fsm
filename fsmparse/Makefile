
STUBDIR = ../standalone_stub
CFLAGS = -I . -I tmp -I $(STUBDIR) -I $(STUBDIR)/utils -W -Wall -Wno-unused

all:
	[ -e tmp ] || mkdir tmp
	bison -d -v -o tmp/fsmparse.cpp fsmparse.y
	touch tmp/fsmparse.hpp
	echo '#ifndef 'fsmparse_h > tmp/fsmparse.h
	echo '#define 'fsmparse_h >> tmp/fsmparse.h
	cat tmp/fsmparse.hpp >> tmp/fsmparse.h
	echo '#endif' >> tmp/fsmparse.h
	rm -f tmp/fsmparse.hpp
	g++ $(CFLAGS) -g -c -o tmp/fsmparse.o tmp/fsmparse.cpp
	g++ $(CFLAGS) -g -c -o tmp/VectorImpl.o $(STUBDIR)/VectorImpl.cpp
	g++ $(CFLAGS) -g -c -o tmp/SharedBuffer.o $(STUBDIR)/SharedBuffer.cpp
	g++ $(CFLAGS) -g -c -o tmp/String8.o $(STUBDIR)/String8.cpp
	g++ $(CFLAGS) -g -c -o tmp/Unicode.o $(STUBDIR)/Unicode.cpp
	g++ $(CFLAGS) -g -c -o tmp/Static.o $(STUBDIR)/Static.cpp
	flex -otmp/fsmlex.cpp fsmlex.l
	g++ $(CFLAGS) -g -c -o tmp/fsmlex.o tmp/fsmlex.cpp
	g++ tmp/fsmparse.o tmp/fsmlex.o tmp/VectorImpl.o tmp/SharedBuffer.o tmp/String8.o tmp/Unicode.o tmp/Static.o -o tmp/fsmparse
