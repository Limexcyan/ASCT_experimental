#!/bin/bash

echo Replacing $1 to $2 ....
find ./ -name "*.m" -type f -exec sed -i "s/$1/$2/g" {} \;
