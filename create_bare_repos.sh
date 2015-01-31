#!/bin/bash

cp -R final dist

for i in $(ls -d dist/*/); do
  for x in $(ls -d ${i}*); do
    if [[ -d $x ]]; then
      #create bare repos
      ( cd ${i} &&  git init --bare ${x##*/}.git --quiet)

      #create repos and push them to their bare repos
      ( cd ${x} && git init --quiet && git add . && git commit -m "initial commit" --quiet && git push ../${x##*/}.git --quiet)

      #delete repos
      ( cd ${i} &&  rm -rf ${x##*/} )
    fi
  done
done
