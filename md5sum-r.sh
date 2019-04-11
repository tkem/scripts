#!/bin/sh

find "$@" -type f -exec md5sum '{}' \;
