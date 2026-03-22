using NetworkInterfaceControllers.NICPreferences

NICPreferences.configure!(
    name_selector_mode=setting(:mode, USE_ALWAYS),
    preferred_interface=setting(:interface, "^hsn[0-9]*\$", MATCH_REGEX),
    interface_name_blacklist=[
        "nmn0", "nmn1", "net0", "net1", " net2", "net3", "net4", "net5",
        "mlx5_bond_0", "bond0", "nmnb0", "nmnn1"
    ],
    hwloc_selector_mode=setting(
        :mode, USE_HOSTNAME,
        "login[01-40],nid[200256-200512,000000-004071,008000-008800]"
    ),
    hwloc_nic_pci_class="Network",
    broker_mode=setting(
        :mode, USE_HOSTNAME,
        "login[01-40],nid[200000-200255,004072-007200]"
    ),
    broker_interface=setting(:interface, "hsnb0:chn", MATCH_EXACT, 3000),
    broker_host_env=["JULIA_NIC_HOST"]
)
