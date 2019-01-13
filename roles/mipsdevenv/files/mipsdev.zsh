export CC=c99
export CXX=$CC
export CFLAGS='-c99 -O2 -I/opt/local/include -L/opt/local/lib'
export CXXFLAGS=$CFLAGS
export CPPFLAGS='-I/opt/local/include -L/opt/local/lib'
export LD_LIBRARY_PATH='/opt/local/lib'
export LDFLAGS='-L/opt/local/lib -Wl,-rpath -Wl,/opt/local/lib'