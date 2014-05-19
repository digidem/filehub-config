modules = \
	header.sh \
	firewall.sh \
	disktag.sh \
	usb_backup.sh \
	usb_remove.sh \
	swap.sh \
	footer.sh

build/EnterRouterMode.sh: ${modules}
	@rm -f $@
	cat > $@ $^
