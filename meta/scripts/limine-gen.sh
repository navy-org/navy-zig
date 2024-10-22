#!/bin/bash

img=$1
modules=${@:2}

if [ -z $img ]; then
    echo "Usage: $0 <image>"
    exit 1
fi

if [ ! -d $img ]; then
    echo "Error: $img is not a directory"
    exit 1
fi

if [ ! -f $img/kernel.elf ]; then
    echo "Error: $img/kernel.elf not found"
    exit 1
fi

cat << EOF > $img/efi/boot/limine.conf
randomize_memory: yes
timeout: 0
/navy
    protocol: limine
    kernel_path: boot():/kernel.elf
EOF

for module in $modules; do
    if [ ! -f $img/$module ]; then
        echo "Error: $img/$module not found"
        exit 1
    fi
    cat << EOF >> $img/efi/boot/limine.conf
$cfg
    module_path: boot():${module}
EOF
done
