#!/bin/sh
gnuplot <<EOF
set title "Time benchmark"
set xlabel "(|V|+|E|)/2"
set ylabel "seconds"
set logscale xy
set term png
set output "time.png"
plot "igraph.time.dat" using 3:(\$1+\$2) with linespoints title "igraph",\
     "cgraph.time.dat" using 3:(\$1+\$2) with linespoints title "cgraph (graphviz)",\
     "Graph.time.dat"  using 3:(\$1+\$2) with linespoints title "Graph (NatDProver)"
quit
EOF
gnuplot <<EOF
set title "Memory benchmark"
set xlabel "(|V|+|E|)/2"
set ylabel "Kbytes"
set logscale xy
set term png
set output "mem.png"
plot "igraph.mem.dat" using 2:1 with linespoints title "igraph",\
     "cgraph.mem.dat" using 2:1 with linespoints title "cgraph (graphviz)",\
     "Graph.mem.dat"  using 2:1 with linespoints title "Graph (NatDProver)"
quit
EOF
