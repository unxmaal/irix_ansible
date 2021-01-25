#!/sbin/sh

cd /tmp/wget_bundle

inst -E -a -f neko_wget-1.11.3.tardist \
  -a -f neko_gettext-0.18.1.1.tardist \
  -a -f neko_glib-2.28.8-11.tardist \
  -a -f neko_libcroco-0.6.2-5.tardist \
  -a -f neko_libiconv-1.14.tardist \
  -a -f neko_libxml2-2.7.8.tardist \
  -a -f neko_ncurses-5.7.tardist \
  -a -f neko_openssl-0.9.8x.tardist \
  -a -f neko_zlib-1.2.5.tardist
