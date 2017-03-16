#!/bin/bash

OPTIND=1
CLEAN=0
BUILD=0
me=`basename "$0"`
LINUXDIR="linux"
FAILED=0

while getopts "hcb" opt; do
        case "$opt" in
            h)
                echo "Usage: $me [-cb]"
                echo "-c is used for cleaning"
                echo "-b is used for building"
                exit 0
                ;;
            c)
                CLEAN=1
                ;;
            b)
                BUILD=1
                ;;
        esac
    done

if [ ! -d "$LINUXDIR" ]; then
    git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
    CLEAN=0
fi

if [ "$CLEAN" -eq "1" ]; then
    cd linux
    while IFS='' read -r line || [[ -n "$line" ]]; do 
        echo "Reverting patch $line"
        patch -R -p1 < "../patches/"$line;
        if [ $? != 0 ]; then
            FAILED=1
        fi
        echo "--------------------------"
    done < "../patches/series"
    cd ..
fi

if [ "$FAILED" -eq "1" ]; then
    echo "Clean failed"
    exit 1
fi

if [ "$BUILD" -eq "1" ]; then
    cd linux
    while IFS='' read -r line || [[ -n "$line" ]]; do 
        echo "Applying patch $line"
        patch -p1 < "../patches/"$line; 
        if [ $? != 0 ]; then
            FAILED=1
        fi
        echo "--------------------------"  
    done < "../patches/series"

    if [ "$FAILED" -eq "1" ]; then
        echo "Patching failed"
        exit 1
    fi
    
    make ARCH=x86_64 CC=clang defconfig
    make ARCH=x86_64 CC=clang
    
    exit $?
fi
