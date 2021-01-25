#!/sbin/sh

cd /tmp/openssh_bundle

inst -E -a -f /tmp/openssh_bundle/neko_openssh-6.2p1.tardist \
  -a -f /tmp/openssh_bundle/neko_openssl-0.9.8x.tardist \
  -a -f /tmp/openssh_bundle/neko_zlib-1.2.5.tardist
