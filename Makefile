# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

BUILDREF	:= $(shell git log --pretty=format:'%h' -n 1)
BUILDDATE	:= $(shell date +%Y%m%d)
BUILDENV	:= dev
BUILDREV	:= $(BUILDDATE)+$(BUILDREF).$(BUILDENV)

# Supported OSes: linux darwin windows
# Supported ARCHes: 386 amd64
OS			:= linux
ARCH		:= amd64

ifeq ($(ARCH),amd64)
	FPMARCH := x86_64
endif
ifeq ($(ARCH),386)
	FPMARCH := i386
endif
ifeq ($(OS),windows)
	BINSUFFIX   := ".exe"
else
	BINSUFFIX	:= ""
endif
PREFIX		:= /usr/local/
DESTDIR		:= /
BINDIR		:= bin/$(OS)/$(ARCH)
GCC			:= gcc
CFLAGS		:=
LDFLAGS		:=
GOOPTS		:=
GO 			:= GOPATH=$(shell go env GOROOT)/bin:$(shell pwd) GOOS=$(OS) GOARCH=$(ARCH) go
GOGETTER	:= GOPATH=$(shell pwd) GOOS=$(OS) GOARCH=$(ARCH) go get -u
GOLDFLAGS	:= -ldflags "-X main.version $(BUILDREV)"
GOCFLAGS	:=
MKDIR		:= mkdir
INSTALL		:= install

all: go_get_deps certRetriever certAnalyser webapi retrieveTLSInfo

retrieveTLSInfo:
	echo building retrieveTLSInfo for $(OS)/$(ARCH)
	$(MKDIR) -p $(BINDIR)
	$(GO) build $(GOOPTS) -o $(BINDIR)/retrieveTLSInfo-$(BUILDREV)$(BINSUFFIX) $(GOLDFLAGS) src/retrieveTLSInfo.go
	[ -x "$(BINDIR)/retrieveTLSInfo-$(BUILDREV)$(BINSUFFIX)" ] && echo SUCCESS && exit 0

certRetriever:
	echo building certRetriever for $(OS)/$(ARCH)
	$(MKDIR) -p $(BINDIR)
	$(GO) build $(GOOPTS) -o $(BINDIR)/certRetriever-$(BUILDREV)$(BINSUFFIX) $(GOLDFLAGS) certRetriever
	[ -x "$(BINDIR)/certRetriever-$(BUILDREV)$(BINSUFFIX)" ] && echo SUCCESS && exit 0

certAnalyser:
	echo building certAnalyser for $(OS)/$(ARCH)
	$(MKDIR) -p $(BINDIR)
	$(GO) build $(GOOPTS) -o $(BINDIR)/certAnalyser-$(BUILDREV)$(BINSUFFIX) $(GOLDFLAGS) certAnalyser
	[ -x "$(BINDIR)/certAnalyser-$(BUILDREV)$(BINSUFFIX)" ] && echo SUCCESS && exit 0

webapi:
	echo building web-api for $(OS)/$(ARCH)
	$(MKDIR) -p $(BINDIR)
	$(GO) build $(GOOPTS) -o $(BINDIR)/web-api-$(BUILDREV)$(BINSUFFIX) $(GOLDFLAGS) web-api
	[ -x "$(BINDIR)/web-api-$(BUILDREV)$(BINSUFFIX)" ] && echo SUCCESS && exit 0

go_get_deps_into_system:
	make GOGETTER="go get -u" go_get_deps

go_get_deps:
	$(GOGETTER) github.com/streadway/amqp
	$(GOGETTER) github.com/mattbaird/elastigo/lib
	$(GOGETTER) github.com/gorilla/mux
	$(GOGETTER) code.google.com/p/gcfg

deb-pkg: all
	rm -fr tmp
	$(MKDIR) -p tmp/opt/observer/bin tmp/etc/observer/
	$(INSTALL) -D -m 0755 $(BINDIR)/certRetriever-$(BUILDREV)$(BINSUFFIX) tmp/opt/observer/bin/certRetriever-$(BUILDREV)$(BINSUFFIX)
	$(INSTALL) -D -m 0755 $(BINDIR)/certAnalyser-$(BUILDREV)$(BINSUFFIX) tmp/opt/observer/bin/certAnalyser-$(BUILDREV)$(BINSUFFIX)
	$(INSTALL) -D -m 0755 $(BINDIR)/web-api-$(BUILDREV)$(BINSUFFIX) tmp/opt/observer/bin/web-api-$(BUILDREV)$(BINSUFFIX)
	$(INSTALL) -D -m 0755 $(BINDIR)/retrieveTLSInfo-$(BUILDREV)$(BINSUFFIX) tmp/opt/observer/bin/retrieveTLSInfo-$(BUILDREV)$(BINSUFFIX)
	$(INSTALL) -D -m 0755 retriever.cfg tmp/etc/observer/retriever.cfg.inc
	$(INSTALL) -D -m 0755 analyzer.cfg tmp/etc/observer/analyzer.cfg.inc
	$(INSTALL) -D -m 0755 moz-CAs.crt tmp/etc/observer/moz-CAs.crt
	$(INSTALL) -D -m 0755 top-1m.csv tmp/etc/observer/top-1m.csv
	fpm -C tmp -n mozilla-tls-observer --license GPL --vendor mozilla --description "Mozilla TLS Observer" \
		-m "Mozilla OpSec" --url https://github.com/mozilla/TLS-Observer --architecture $(FPMARCH) -v $(BUILDREV) \
		-s dir -t deb .

clean:
	rm -rf bin
	find src/ -maxdepth 1 -mindepth 1 -name github* -exec rm -rf {} \;

.PHONY: clean