# Standard part of Makefile for topdir.
TOPLEVEL_INCLUDED=YES

ifndef KERNEL_DIR
KERNEL_DIR=/usr/src/linux
endif
NETFILTER_VERSION:=1.0.0
OLD_NETFILTER_VERSION:=1.0.0beta

LIBDIR:=/usr/local/lib
BINDIR:=/usr/local/bin
MANDIR:=/usr/local/man

COPT_FLAGS:=-O2
CFLAGS:=$(COPT_FLAGS) -Wall -Wunused -Iinclude/ -I$(KERNEL_DIR)/include -DNETFILTER_VERSION=\"$(NETFILTER_VERSION)\" #-g -pg

DEPFILES := $(SHARED_LIBS:%.so=%.d)
SH_CFLAGS:=$(CFLAGS) -fPIC
DEPFILES := $(SHARED_LIBS:%.so=%.d)

EXTRAS+=iptables iptables.o #iptables-save iptables-restore
EXTRA_INSTALLS+=$(DESTDIR)$(BINDIR)/iptables $(DESTDIR)$(MANDIR)/man8/iptables.8 #$(DESTDIR)$(BINDIR)/iptables-save $(DESTDIR)$(BINDIR)/iptables-restore

ifndef IPT_LIBDIR
IPT_LIBDIR:=$(LIBDIR)/iptables
endif

default: all

iptables.o: iptables.c
	$(CC) $(CFLAGS) -DIPT_LIB_DIR=\"$(IPT_LIBDIR)\" -c -o $@ $<

iptables: iptables-standalone.c iptables.o libiptc/libiptc.a
	$(CC) $(CFLAGS) -DIPT_LIB_DIR=\"$(IPT_LIBDIR)\" -rdynamic -o $@ $^ -ldl

$(DESTDIR)$(BINDIR)/iptables: iptables
	@[ -d $(DESTDIR)$(BINDIR) ] || mkdir -p $(DESTDIR)$(BINDIR)
	cp $< $@

iptables-save: iptables-save.c iptables.o libiptc/libiptc.a
	$(CC) $(CFLAGS) -DIPT_LIB_DIR=\"$(IPT_LIBDIR)\" -rdynamic -o $@ $^ -ldl

$(DESTDIR)$(BINDIR)/iptables-save: iptables-save
	@[ -d $(DESTDIR)$(BINDIR) ] || mkdir -p $(DESTDIR)$(BINDIR)
	cp $< $@

iptables-restore: iptables-restore.c iptables.o libiptc/libiptc.a
	$(CC) $(CFLAGS) -DIPT_LIB_DIR=\"$(IPT_LIBDIR)\" -rdynamic -o $@ $^ -ldl

$(DESTDIR)$(BINDIR)/iptables-restore: iptables-restore
	@[ -d $(DESTDIR)$(BINDIR) ] || mkdir -p $(DESTDIR)$(BINDIR)
	cp $< $@

$(DESTDIR)$(MANDIR)/man8/iptables.8: iptables.8
	@[ -d $(DESTDIR)$(MANDIR)/man8 ] || mkdir -p $(DESTDIR)$(MANDIR)/man8
	cp $< $@

EXTRA_DEPENDS+=iptables-standalone.d iptables.d

iptables-standalone.d iptables.d: %.d: %.c
	@-$(CC) -M -MG $(CFLAGS) $< | sed -e 's@^.*\.o:@$*.d $*.o:@' > $@

distclean: clean
	@rm -f TAGS `find . -name '*~'` `find . -name '*.rej'` `find . -name '*.d'` .makefirst

# Rusty's distro magic.
distrib: check nowhitespace distclean delrelease /home/public/netfilter/iptables-$(NETFILTER_VERSION).tar.bz2 diff md5sums

# Makefile must not define:
# -g -pg
check:
	@if echo $(CFLAGS) | egrep 'DEBUG|-g|-pg' >/dev/null; then echo Remove debugging flags; exit 1; else exit 0; fi

nowhitespace:
	@if grep -n ' 	$$' `find . -name 'Makefile' -o -name '*.[ch]'`; then exit 1; else exit 0; fi

delrelease:
	rm -f /home/public/netfilter/iptables-$(NETFILTER_VERSION).tar.bz2

/home/public/netfilter/iptables-$(NETFILTER_VERSION).tar.bz2:
	cd .. && ln -sf userspace iptables-$(NETFILTER_VERSION) && tar cvf - --exclude CVS iptables-$(NETFILTER_VERSION)/. | bzip2 -9 > $@ && rm iptables-$(NETFILTER_VERSION)

diff: /home/public/netfilter/iptables-$(NETFILTER_VERSION).tar.bz2
	@mkdir /tmp/diffdir
	@cd /tmp/diffdir && tar xfI /home/public/netfilter/iptables-$(NETFILTER_VERSION).tar.bz2
	@set -e; cd /tmp/diffdir; tar xfI /home/public/netfilter/iptables-$(OLD_NETFILTER_VERSION).tar.bz2; echo Creating patch-iptables-$(OLD_NETFILTER_VERSION)-$(NETFILTER_VERSION).bz2; diff -urN iptables-$(OLD_NETFILTER_VERSION) iptables-$(NETFILTER_VERSION) | bzip2 -9 > /home/public/netfilter/patch-iptables-$(OLD_NETFILTER_VERSION)-$(NETFILTER_VERSION).bz2
	@rm -rf /tmp/diffdir

md5sums:
	cd /home/public/netfilter/ && md5sum patch-iptables-*-$(NETFILTER_VERSION).bz2 iptables-$(NETFILTER_VERSION).tar.bz2

# $(wildcard) fails wierdly with make v.3.78.1.
include $(shell echo */Makefile)
include Rules.make