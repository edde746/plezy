#!/bin/bash

set -e

if [ "$1" == "ios" ]; then
  if [[ ! -d ./tvos ]] && [[ -d ./_ios ]] && [[ -d ./ios ]]; then
    echo "Renaming 'ios' to 'tvos'"
    mv ./ios ./tvos
    mv ./_ios ./ios
  else
    echo "'tvos' already exists or '_ios'/'ios' does not exist"
    exit 1
  fi   

elif [[ "$1" == "tvos" ]] ; then
  if [[ ! -d ./_ios ]] && [[ -d ./tvos ]] && [[ -d ./ios ]]; then
    echo "Renaming 'tvos' to 'ios'"
    mv ./ios ./_ios
    mv ./tvos ./ios
  else
    echo "'_ios' already exists or 'tvos'/'ios' does not exist"
    exit 1
  fi   

else
  echo "invalid arguments:"
  echo " Usage: $0 ios  or  $0 tvos"
  exit 1
fi