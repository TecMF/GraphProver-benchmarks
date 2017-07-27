CFLAGS= -Wall -Werror $(shell pkg-config --cflags glib-2.0)
CXXFLAGS= $(CFLAGS)
LDFLAGS= $(shell pkg-config --libs glib-2.0)
PROGRAMS= test-igraph test-cgraph

rep_time= igraph.time.dat cgraph.time.dat Graph.time.dat
rep_mem = igraph.mem.dat  cgraph.mem.dat  Graph.mem.dat
REPORTS= $(rep_time) $(rep_mem)

all: $(PROGRAMS)
.PHONY: all

.PHONY: clean
clean:
	-rm -f $(PROGRAMS)
	-rm -f *.dot *.graphml

.PHONY: report
report: all $(REPORTS)
	./plot.sh

TIME= /usr/bin/time
time= $(TIME) -o $(1).time.dat -a -f "%U\t%S\t$(2)" ./test-$(1) $(2) $(2) .75
mem=  $(TIME) -o $(1).mem.dat -a -f "%M\t$(2)" ./test-$(1) $(2) $(2) .75

.PHONY: measure-time
measure-time:
	$(call time,$(TEST),$(N))

.PHONY: measure-mem
measure-mem:
	$(call mem,$(TEST),$(N))

$(rep_time):
	$(MAKE) measure-time TEST=$(@:.time.dat=) N=1000
	$(MAKE) measure-time TEST=$(@:.time.dat=) N=2000
	$(MAKE) measure-time TEST=$(@:.time.dat=) N=4000
	$(MAKE) measure-time TEST=$(@:.time.dat=) N=8000
	$(MAKE) measure-time TEST=$(@:.time.dat=) N=16000
	$(MAKE) measure-time TEST=$(@:.time.dat=) N=32000
	$(MAKE) measure-time TEST=$(@:.time.dat=) N=64000
	$(MAKE) measure-time TEST=$(@:.time.dat=) N=128000
	$(MAKE) measure-time TEST=$(@:.time.dat=) N=512000
	$(MAKE) measure-time TEST=$(@:.time.dat=) N=1024000
$(rep_mem):
	$(MAKE) measure-mem  TEST=$(@:.mem.dat=)  N=1000
	$(MAKE) measure-mem  TEST=$(@:.mem.dat=)  N=2000
	$(MAKE) measure-mem  TEST=$(@:.mem.dat=)  N=4000
	$(MAKE) measure-mem  TEST=$(@:.mem.dat=)  N=8000
	$(MAKE) measure-mem  TEST=$(@:.mem.dat=)  N=16000
	$(MAKE) measure-mem  TEST=$(@:.mem.dat=)  N=32000
	$(MAKE) measure-mem  TEST=$(@:.mem.dat=)  N=64000
	$(MAKE) measure-mem  TEST=$(@:.mem.dat=)  N=128000
	$(MAKE) measure-mem  TEST=$(@:.mem.dat=)  N=512000
	$(MAKE) measure-mem  TEST=$(@:.mem.dat=)  N=1024000

IGRAPH=$(shell pkg-config --cflags --libs igraph)
test-igraph: test-igraph.c
	$(CC) $(CFLAGS) $(LDFLAGS) $(IGRAPH) -o $@ $^

CGRAPH=$(shell pkg-config --cflags --libs libcgraph)
test-cgraph: test-cgraph.c
	$(CC) $(CFLAGS) $(LDFLAGS) $(CGRAPH) -o $@ $^
