#!/bin/bash

path=$1
addr=$2

out=$(llvm-addr2line -e $path $addr)
nvim $(echo $out | cut -d ":" -f 1) +$(echo $out | cut -d ":" -f 2)
