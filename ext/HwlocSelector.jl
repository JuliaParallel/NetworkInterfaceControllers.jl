module HwlocSelector

using Hwloc, AbstractTrees

function get_cpu_id(pid=getpid())
    topo = Hwloc.topology_init() 
    ierr = Hwloc.LibHwloc.hwloc_topology_load(topo)
    @assert ierr == 0

    bm = Hwloc.LibHwloc.hwloc_bitmap_alloc()

    Hwloc.LibHwloc.hwloc_get_proc_last_cpu_location(
        topo, pid, bm, Hwloc.LibHwloc.HWLOC_CPUBIND_THREAD
    )
    cpu_id = Hwloc.LibHwloc.hwloc_bitmap_first(bm)

    Hwloc.LibHwloc.hwloc_bitmap_free(bm)
    Hwloc.LibHwloc.hwloc_topology_destroy(htopo)

    return cpu_id
end


end
