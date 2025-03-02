using NetworkInterfaceControllers.NICPreferences

NICPreferences.configure!(
    name_selector_mode=setting(:mode, USE_ALWAYS),
    preferred_interface=setting(:interface, "^wlp[0-9]*s[0-9]*\$", MATCH_REGEX),
    interface_name_whitelist=["docker0"],
    hwloc_selector_mode=setting(:mode, USE_ALWAYS),
    hwloc_nic_pci_class="Network",
    broker_mode=setting(:mode, USE_ALWAYS),
    broker_interface=setting(:interface, "^wlp[0-9]*s[0-9]*\$", MATCH_REGEX, 3000)
)
