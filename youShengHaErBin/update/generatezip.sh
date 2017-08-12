#!/bin/sh

rm -rf temp
mkdir -p temp

cp -r -f ../res temp
cp -r -f ../src temp

cd temp

cocos jscompile -s src -d src

zip -r update.zip ./* -x "*.js"

mv -f update.zip ../update.zip

cd ../

rm -rf temp


