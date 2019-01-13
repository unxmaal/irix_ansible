setenv CC c99
setenv CXX CC
setenv CFLAGS '-c99 -O2 -I/opt/local/include -L/opt/local/lib'
setenv CXXFLAGS CFLAGS
setenv CPPFLAGS '-I/opt/local/include -L/opt/local/lib'
setenv LD_LIBRARY_PATH '/opt/local/lib'
setenv LDFLAGS '-L/opt/local/lib -Wl,-rpath -Wl,/opt/local/lib'