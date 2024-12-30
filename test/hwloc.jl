using Hwloc, AbstractTrees, NetworkInterfaceControllers

HwlocSelector = NetworkInterfaceControllers.get_hwloc_selector()
topo = children(gettopology())
net = HwlocSelector.get_network_devices(topo) |> collect
cpuid = HwlocSelector.get_cpu_id()

println(cpuid)
println(
    HwlocSelector.distance_to_core(topo, net[1], cpuid)
)
