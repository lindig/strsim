# Strsim - compare two strings and emit those that are similar

This is a small utility that compares two strings that it reads from stdin for
similarity and emits those that exceed a given threshold. It was developed for
detecting personal names that are likely to be equal.

        $ echo "Donald Knuth^Donald E. Knuth" | ./strsim -t '^' -d 0.8
        
The invocation above would emit the line because it finds the two
strings `Donald Knuth` and `Donald E. Knuth` similar.

Several metrics for comparing strings exist where the editing distance it
probably the best known. This tool implements another algorithm that is
relatively robust against swapped characters and small additions and
deletions. The algorithm builds for each string a set of all adjacent
characters (a set of pairs) and compares these:

Let x and y be strings and xs and ys the corresponding sets of adjacent pairs
from these string and ss their intersection. The similarity s of x and y is
computed as

        s = (2*|ss|)/(|xs|+|ys|)
        
where |xs| denotes the cardinality of set |xs|. Example:

        x = hello
        y = hallo (German for hello)
        
        xs = {he,el,ll,lo}
        ys = {ha,al,ll,lo}
        ss = {ll,lo}

        s = (2*2)/(4+3) = 4/7 = 0.57
        
## Usage and Options

        ./strsim -h
        usage: strsim options

        strsim reads lines from stdin, splits them in two halfs 
        and emits all lines whose half exceed a given similarity 
        threshold in range 0.0..1.0

        options:
        -t c     split input lines at character c; default is tab
        -d 0.8   emit lines with similarity of 0.8 or greater; default 0.9
        -h       emit this help to stderr


Strsim reads input line by line from stdin and splits each line into two
strings which it compares. The line is spilt at the first tab character, or
the character by option `-t` if provided. The threshold that needs to be
exceeded is 0.9 by default and is likewise controlled by option `-d`.

## Building

Strsim is implemented in Objective Caml. To build it, simply invoke Make:

        $ make
        
The `Makefile` relies on `ocamlbuild` for the actual build process.

## Author

Christian Lindig <lindig@gmail.com>

## Copyright

This code is in the public domain.



