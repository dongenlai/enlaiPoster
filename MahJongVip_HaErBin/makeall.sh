echo "make all"
make -f MakefileMgr clean
make -f MakefileMgr -j3
make -f MakefileArea clean
make -f MakefileArea -j3


