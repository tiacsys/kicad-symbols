#!/bin/bash

for SUBDIR in *.kicad_symdir; do
  echo $SUBDIR
  LIBNAME=$(echo $SUBDIR | cut -d . -f1)

  # overwrite all files
  for FILENAME in $SUBDIR/*.kicad_sym; do
    cp "../$LIBNAME.kicad_sym" "$FILENAME"
  done
done

git commit -m "Add renamed files with copies of full libraries"
