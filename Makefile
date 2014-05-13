modules = \
	header.sh \
	firewall.sh \
	usb_backup.sh \
	usb_remove.sh \
	footer.sh

build/EnterRouterMode.sh: ${modules}
	@rm -f $@
	cat > $@ $^
