using Hwloc, AbstractTrees, NetworkInterfaceControllers

HwlocSelector = NetworkInterfaceControllers.get_hwloc_selector()
cpuid = HwlocSelector.get_cpu_id()
dist = HwlocSelector.hwloc_nic_distances(cpuid)

println(dist)

