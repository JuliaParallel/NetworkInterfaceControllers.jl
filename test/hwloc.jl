using Hwloc, AbstractTrees, NetworkInterfaceControllers

HwlocSelector = NetworkInterfaceControllers.get_hwloc_selector()
topo = children(gettopology())
net = HwlocSelector.get_network_devices(topo) |> collect
cpuid = HwlocSelector.get_cpu_id()

println("cpuid=$(cpuid)")

for n in net
    name = HwlocSelector.hwloc_nic_name(n)
    println("name=$(name)")
    for i=0:7
        println(
            "$(i): $(HwlocSelector.distance_to_core(topo, net[1], i))"
        )
    end
end
