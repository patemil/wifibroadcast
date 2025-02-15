VERSION ?= $(shell ./version.py)
COMMIT ?= $(shell git rev-parse HEAD)

export VERSION COMMIT

_LDFLAGS := $(LDFLAGS) -lrt -lpcap -lsodium
# WFB_VERSION is date and time and the last commit of this branch
_CFLAGS := $(CFLAGS)  -O2 -DWFB_VERSION='"$(VERSION)-$(shell /bin/bash -c '_tmp=$(COMMIT); echo $${_tmp::8}')"'

# depending on the architecture we need the right flags for optimized fec encoding/decoding
uname_S := $(shell sh -c 'uname -s 2>/dev/null || echo not')
ifeq ($(uname_S),Linux)
	uname_M := $(shell sh -c 'uname -m 2>/dev/null || echo not')
	ifeq ($(uname_M),x86_64)
		_CFLAGS += -mavx2 -faligned-new=256
	else ifeq ($(uname_M),armv7l)
 		_CFLAGS += -mfpu=neon -march=armv7-a -marm
	endif
endif

all_bin: wfb_rx wfb_tx wfb_keygen unit_test benchmark udp_generator_validator
all: all_bin gs.key

# Just compile everything as c++ code
# compile radiotap
src/external/radiotap/%.o: src/external/radiotap/%.c src/external/radiotap/*.h
	$(CC) $(_CFLAGS) -std=c++17 -c -o $@ $<

# compile the (general) fec part
src/external/fec/%.o: src/external/fec/%.cpp src/external/fec/*.h src/external/fec/gf_optimized
	$(CXX) $(_CFLAGS) -std=c++17 -c -o $@ $<

# the c++ part
src/%.o: src/%.cpp src/*.hpp
	$(CXX) $(_CFLAGS) -std=c++17 -c -o $@ $<

wfb_rx: src/rx.o src/external/radiotap/radiotap.o src/external/fec/fec.o
	$(CXX) -o $@ $^ $(_LDFLAGS)

wfb_tx: src/tx.o src/external/radiotap/radiotap.o src/external/fec/fec.o
	$(CXX) -o $@ $^ $(_LDFLAGS)

unit_test: src/unit_test.o src/external/fec/fec.o
	$(CXX) -o $@ $^ $(_LDFLAGS)

benchmark: src/benchmark.o src/external/fec/fec.o
	$(CXX) -o $@ $^ $(_LDFLAGS)

udp_generator_validator: src/udp_generator_validator.o
	$(CXX) -o $@ $^ $(_LDFLAGS)

wfb_keygen: src/keygen.o
	$(CC) -o $@ $^ $(_LDFLAGS)

gs.key: wfb_keygen
	@if ! [ -f gs.key ]; then ./wfb_keygen; fi

clean:
	rm -rf env wfb_rx wfb_tx wfb_keygen unit_test benchmark udp_generator_validator src/*.o src/external/fec/*.o src/external/radiotap/*.o


# experimental
.PHONY: install
install:
	cp -f wfb_tx wfb_rx benchmark udp_generator_validator unit_test wfb_keygen $(TARGET_DIR)/usr/local/bin/

.PHONY: uninstall
uninstall:
	rm -f $(TARGET_DIR)/usr/local/bin/wfb_*
