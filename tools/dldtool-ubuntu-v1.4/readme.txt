USAGE:
(1) Burn flash data
	./dldtool <COMMON-OPTIONS> [ -m <address>[/<value>] ] <programmerFile> <FLASH-FILE-LIST>
(2) Erase sector
	./dldtool <COMMON-OPTIONS> -e <address>[/<length>] <programmerFile>
(3) Erase the whole chip
	./dldtool <COMMON-OPTIONS> --erase-chip <programmerFile>
(4) Burn security register data
	./dldtool <COMMON-OPTIONS> [ --sec-magic <address>[/<value>] ] <programmerFile>
		{ [ --sec-addr <address> ] [ --no-sec-default-magic ] --sec-file <secRegFile> |
		   --sec-lock <address>[/<length>] }
(5) Erase security register
	./dldtool <COMMON-OPTIONS> --sec-erase <address>[/<length>] <programmerFile>
(6) Ramrun programmer
	./dldtool <COMMON-OPTIONS> --ramrun <programmerFile>
(7) Read efuse
	./dldtool <COMMON-OPTIONS> --efuse-read <page> <programmerFile>
(8) Write efuse
	./dldtool <COMMON-OPTIONS> --efuse-write <page>/<value> <programmerFile>

COMMON-OPTIONS:
	{ [ -b <baudRate> ] <comPortNum> | [ --usb-verbose ] usb } [ -v ] [ --no-sync ]
	[ --no-shutdown | --reboot ] [ --no-default-magic ] [ --pgm-rate <baudRate> ]
	[ --force-uart | --force-usb ] [ --retry <maxRetryCnt> | --no-retry ]
	[ --w4 <address>/<value> ] [ --u4 <address>/<value>/<mask> ]

FLASH-FILE-LIST:
	<FLASH-FILE 1> [ <FLASH-FILE 2> ... ]

FLASH-FILE:
	[ --addr <address> ] [ { --remap | --remap-both } <remapOffset> ] <flashFile>

DESCRIPTION:
	-b <baudRate>	Optional. Specify COM port baud rate
	<ttyPort>	serial device device
	--usb-verbose	Optional. Enable usb verbose trace
	usb		Monitor USB serial plugin and extract COM number automatically
	-v		Optional. Enable download verbose trace
	--no-sync	Optional. Skip the first sync operation
	--no-shutdown	Optional. Skip the shutdown or reboot operation when finished
	--reboot	Optional. Reboot when finished
	--no-default-magic
			Optional. Skip the default magic number burning operation
	--pgm-rate <baudRate>
			Optional. Change programmer uart baud rate
	--sector-size-kib <sectorSizeKiB>
			Optional. Set sector size in KiB (default 32 KiB)
	--force-uart	Optional. Force uart mode
	--force-usb	Optional. Force usb mode
	--sec-boot-ver <secBootVer>
			Optional.Specify the secure boot version (0 stands for the newest version)
	--retry <maxRetryCnt>
			Optional. Specify the max retry count in case of failure
	--no-retry	Optional. Never retry in case of failure
	--w4 <address>/<value>
			Optional.Write memory before running programmer
	--u4 <address>/<value>/<mask>
			Optional. Update memory before running programmer
	-M		Optional.Burn the default magic number value for the following flash binary
			file or security register data file
	--auto-magic <value>
			Optional. Burn the magic number value for the following flash binary
			file or security register data file
	-m <address>[/<value>]
			Optional. Specify magic number address and value
			This option can occur multiple times
	-e <address>[/<length>]
			Mandatory. Specify sector address and length to be erased
			This option can occur multiple times
	--erase-chip	Mandatory. Erase the whole flash chip
	--erase-chip-index <index>
			Mandatory. Erase the specified flash chip. (-1 for boot chip and -2 for all chips)
	--erase-chip-addr <address>
			Mandatory. Erase the specified flash chip. (erase boot chip if address not found)
	--set-dual-chip <mode>
			Optional. Set dual chip mode for the boot flash chip.
			(0 to disable, 1 to enable flash dual chip, 2 to enable flash and secReg dual chip)
	--set-dual-chip-index <index>/<mode>
			Optional. Set dual chip mode for the specified flash chip. (-1 for boot chip)
	--set-dual-chip-addr <address>/<mode>
			Optional. Set dual chip mode for the specified flash chip. (boot chip if not found)
	<programmerFile>
			Programmer binary file
	--addr <address>
			The following flash binary file is burned on given address
			If omitted, the address is extracted from the tail of file
	--remap <remapOffset>
			The following flash binary file is burned on remapped address
	--remap-both <remapOffset>
			The following flash binary file is burned on both normal and remapped address
	<flashFile>	Flash binary file
	--sec-addr <address>
			Optional. Specify the address of the following security register data file
			If omitted, the address is extracted from the tail of file
	--no-sec-default-magic
			Optional. Skip the security register default magic number burning operation
	--sec-file <secRegFile>
			Optional. Specify security register data file to be burned
			This option can occur multiple times
	--sec-magic <address>[/<length>]
			Optional. Specify security register magic number address and value
			This option can occur multiple times
	--sec-lock <address>[/<length>]
			Optional. Specify security register address and length to be locked
			This option can occur multiple times
	--sec-erase <address>[/<length>]
			Mandatory. Specify security register address and length to be erased
	--efuse-read <page>
			Mandatory. Read the efuse page
	--efuse-write <page>/<value>
			Mandatory. Write the efuse page
			This option can occur multiple times

Examples:
	./dldtool /dev/ttyUSB0 ./out/programmer.bin ./out/best.bin
