#!/sbin/sh

cd /tmp/python_bundle

/usr/sbin/inst -E -a -f neko_python-2.7.3.tardist \
-a -f neko_bzip2-1.0.6.tardist \
-a -f neko_db4-4.4.20.tardist \
-a -f neko_expat-2.1.0.tardist \
-a -f neko_gdbm-1.8.3.tardist \
-a -f neko_gettext-0.18.1.1.tardist \
-a -f neko_libiconv-1.14.tardist \
-a -f neko_ncurses-5.7.tardist \
-a -f neko_openssl-0.9.8x.tardist \
-a -f neko_readline-6.1-4.tardist \
-a -f neko_sqlite3-3.7.10.tardist \
-a -f neko_tcl-8.4.11.tardist \
-a -f neko_tk-8.4.11.tardist \
-a -f neko_zlib-1.2.5.tardist \
-a -f neko_glib-2.28.8-11.tardist \
-a -f neko_libcroco-0.6.2-5.tardist \
-a -f neko_libxml2-2.7.8.tardist
