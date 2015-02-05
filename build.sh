#!/bin/bash -xe

#build the target library
gcc -g -ansi -c -fPIC api/api.c -o api.o
gcc -shared -o libapi.so api.o
