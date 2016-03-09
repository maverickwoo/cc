# Copyright 2016 The CC Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

.PHONY:	all clean cover cpu edit editor internalError later mem nuke todo

grep=--include=*.go --include=*.l --include=*.y

all: editor
	go vet || true
	golint || true
	make todo

clean:
	go clean
	rm -f *~ cpu.test mem.test

cover:
	t=$(shell tempfile) ; go test -coverprofile $$t && go tool cover -html $$t && unlink $$t

cpu:
	go test -c -o cpu.test
	./cpu.test -noerr -test.cpuprofile cpu.out
	go tool pprof --lines cpu.test cpu.out

edit:
	gvim -p Makefile trigraphs.l scanner.l parser.yy parser.y y.output *.go

editor: parser.go scanner.go trigraphs.go
	gofmt -l -s -w *.go
	rm -f log-*.c log-*.h
	go test 2>&1 | tee log
	go install

internalError:
	egrep -ho '"internal error.*"' *.go | sort | cat -n

later:
	@grep -n $(grep) LATER * || true
	@grep -n $(grep) MAYBE * || true

mem:
	go test -c -o mem.test
	./mem.test -test.bench . -test.memprofile mem.out
	go tool pprof --lines --web --alloc_space mem.test mem.out

nuke: clean
	go clean -i

parser.go scanner.go trigraphs.go: parser.yy trigraphs.l scanner.l
	go test -i
	go generate

todo:
	@grep -n $(grep) ^[[:space:]]*_[[:space:]]*=[[:space:]][[:alpha:]][[:alnum:]]* * || true
	@grep -n $(grep) TODO * || true
	@grep -n $(grep) BUG * || true
	@grep -n $(grep) [^[:alpha:]]println * || true
