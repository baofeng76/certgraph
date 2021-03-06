GIT_DATE := $(shell git log -1 --date=short --pretty='%cd' | tr -d -)
GIT_HASH := $(shell git rev-parse HEAD)

BUILD_FLAGS := -ldflags "-X main.git_date=$(GIT_DATE) -X main.git_hash=$(GIT_HASH)"

PLATFORMS := linux/amd64 linux/386 linux/arm darwin/amd64 windows/amd64 windows/386 openbsd/amd64
SOURCES := $(shell find . -maxdepth 1 -type f -name "*.go")
ALL_SOURCES = $(shell find . -type f -name '*.go' -not -path "./vendor/*")
DEP_EXISTS := $(shell command -v dep 2> /dev/null)

temp = $(subst /, ,$@)
os = $(word 1, $(temp))
arch = $(word 2, $(temp))
ext = $(shell if [ "$(os)" = "windows" ]; then echo ".exe"; fi)

.PHONY: all release fmt clean serv dep godep $(PLATFORMS)

all: certgraph

release: $(PLATFORMS)
	rm -r build/bin/

certgraph: $(SOURCES) $(ALL_SOURCES)
	go build $(BUILD_FLAGS) -o $@ $(SOURCES)

$(PLATFORMS): $(SOURCES)
	CGO_ENABLED=0 GOOS=$(os) GOARCH=$(arch) go build $(BUILD_FLAGS) -o 'build/bin/$(os)/$(arch)/certgraph$(ext)' $(SOURCES)
	mkdir -p build/$(GIT_DATE)/; cd build/bin/$(os)/$(arch)/; zip -r ../../../$(GIT_DATE)/certgraph-$(os)-$(arch)-$(GIT_DATE).zip .; cd ../../../

dep: godep
	dep ensure -v

godep:
ifndef DEP_EXISTS
	go get -u github.com/golang/dep/cmd/dep 
endif

fmt:
	gofmt -s -w -l .

install: $(SOURCES) $(ALL_SOURCES)
	go install $(BUILD_FLAGS)

clean:
	rm -r certgraph build/

serv:
	(cd docs; python -m SimpleHTTPServer)
