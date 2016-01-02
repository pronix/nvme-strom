nvme-y	:= nvme-core.o nvme-scsi.o

obj-m	+= nvme.o

all:
	$(MAKE) -C /usr/lib/modules/$(shell uname -r)/build M=$(shell pwd) nvme.ko
