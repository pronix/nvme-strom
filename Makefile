nvme-y	:= nvme-core.o nvme-scsi.o

obj-m	+= nvme.o

EXTRA_CLEANS := nvme-strom.upgrade.diff

all:
	$(MAKE) -C /usr/lib/modules/$(shell uname -r)/build M=$(shell pwd) nvme.ko

clean:
	rm -f $(EXTRA_CLEANS)
	$(MAKE) -C /usr/lib/modules/$(shell uname -r)/build M=$(shell pwd) clean
