#!/bin/sh
gnuplot <<EOF
set title "Time benchmark"
set xlabel "(|V|+|E|)/2"
set ylabel "seconds"
set pointsize 1.5
set term png
set output "time.png"
plot "igraph.time.dat" using 3:(\$1+\$2) with linespoints title "igraph",\
     "cgraph.time.dat" using 3:(\$1+\$2) with linespoints title "cgraph (graphviz)"
quit
EOF
gnuplot <<EOF
set title "Memory benchmark"
set xlabel "(|V|+|E|)/2"
set ylabel "Kbytes"
set pointsize 1.5
set term png
set output "mem.png"
plot "igraph.mem.dat" using 2:1 with linespoints title "igraph",\
     "cgraph.mem.dat" using 2:1 with linespoints title "cgraph (graphviz)"
quit
EOF