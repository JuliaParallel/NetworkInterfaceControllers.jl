using NetworkInterfaceControllers.NICPreferences

NICPreferences.configure!(
    name_selector_mode=setting(:mode, USE_ALWAYS),
    preferred_interface=setting(:interface, "^(lo|en)[0-9]*\$", MATCH_REGEX),
    interface_name_blacklist=[
        "bridge0", "gif0", "stf0", "anpi0", "anpi1", "anpi2", "ap1", "awdl0",
        "llw0", "utun0", "utun1", "utun2", "utun3"
    ],
    hwloc_selector_mode=setting(:mode, USE_ALWAYS),
    hwloc_nic_pci_class="Network",
    broker_mode=setting(:mode, USE_ALWAYS),
    broker_interface=setting(:interface, "^en0\$", MATCH_REGEX, 3000),
    broker_host_env=["JULIA_NIC_HOST"]
)
