CFLAGS= -Wall -Werror $(shell pkg-config --cflags glib-2.0)
CXXFLAGS= $(CFLAGS)
LDFLAGS= $(shell pkg-config --libs glib-2.0)
PROGRAMS= test-igraph test-cgraph

all: $(PROGRAMS)
.PHONY: all

.PHONY: clean
clean:
	-rm -f $(PROGRAMS)
	-rm -f *.dot *.graphml *.dat *.png

.PHONY: report
report: all igraph.time.dat igraph.mem.dat cgraph.mem.dat cgraph.time.dat
	./plot.sh

sizes:= $(shell for ((i=1000; i<=1024*1024; i=i*2)); do echo $$i; done)
TIME= /usr/bin/time
time= $(TIME) -o $(1).time.dat -a -f "%U\t%S\t$(2)" ./test-$(1) $(2) $(2) .75
mem=  $(TIME) -o $(1).mem.dat -a -f "%M\t$(2)" ./test-$(1) $(2) $(2) .75

igraph.time.dat:
	$(foreach n, $(sizes), $(call time,igraph,$(n));)
igraph.mem.dat:
	$(foreach n, $(sizes), $(call mem,igraph,$(n));)

cgraph.time.dat:
	$(foreach n, $(sizes), $(call time,cgraph,$(n));)
cgraph.mem.dat:
	$(foreach n, $(sizes), $(call mem,cgraph,$(n));)

IGRAPH=$(shell pkg-config --cflags --libs igraph)
test-igraph: test-igraph.c
	$(CC) $(CFLAGS) $(LDFLAGS) $(IGRAPH) -o $@ $^

CGRAPH=$(shell pkg-config --cflags --libs libcgraph)
test-cgraph: test-cgraph.c
	$(CC) $(CFLAGS) $(LDFLAGS) $(CGRAPH) -o $@ $^
