MKCWD = @mkdir -p $(@D)
LIMINE_GEN = ./meta/scripts/limine-gen.sh

SYSROOT = ./.image/
CACHE = ./.cache/

LOADER = $(SYSROOT)/efi/boot/bootx64.efi
KERNEL = $(SYSROOT)/kernel.elf
FIRMWARE = $(CACHE)/OVMF.fd

SRC = $(shell find . -name '*.zig')

$(LOADER):
	@$(MKCWD)
	@curl -L https://github.com/limine-bootloader/limine/raw/refs/heads/v8.x-binary/BOOTX64.EFI -o $@

$(KERNEL): $(SRC)
	@$(MKCWD)
	@zig build
	@cp ./zig-out/bin/kernel.elf $@

$(FIRMWARE):
	@$(MKCWD)
	@curl -L https://retrage.github.io/edk2-nightly/bin/RELEASEX64_OVMF.fd -o $@

.PHONY: qemu
qemu: $(LOADER) $(KERNEL) $(FIRMWARE)
	@bash $(LIMINE_GEN) $(SYSROOT)
	qemu-system-x86_64 --no-reboot --no-shutdown -smp 4 -serial mon:stdio \
		-display none \
		-drive format=raw,file=fat:rw:$(SYSROOT) \
		-bios $(FIRMWARE)

.PHONY: clean
clean:
	@zig clean

.PHONY: nuke
nuke: clean
	rm -rf $(SYSROOT)
