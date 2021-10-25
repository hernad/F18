#!/bin/sh

find .   -name "*.bak"  ! -path docker -exec echo \{\} \; -exec rm \{\} \;

