module HwlocSelector

using Hwloc, AbstractTrees, NetworkInterfaceControllers

struct TraversalHistory{T}
    visited::IdDict{T, Bool}

    function TraversalHistory(root::T) where T
        visited = IdDict{T, Bool}()
        for c in PreOrderDFS(root)
            visited[c] = false
        end
        new{T}(visited)
    end
end

Base.getindex(th::TraversalHistory{T}, k::T) where T = th.visited[k]
Base.setindex!(th::TraversalHistory{T}, v::Bool, k::T) where T = th.visited[k] = v
Base.keys(th::TraversalHistory{T}) where T = keys(th.visited)

function visit!(node::T, history::TraversalHistory{T})::Nothing where T
    history[node] = true
    return nothing
end

function visited(node::T, history::TraversalHistory{T})::Bool where T
    return history[node]
end

function reset(history::TraversalHistory{T})::Nothing where T
    for k in keys(history)
        history[k] = false
    end
    return nothing
end

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
    Hwloc.LibHwloc.hwloc_topology_destroy(topo)

    return cpu_id
end

export get_cpu_id

function distance_to_core!(
        th::TraversalHistory{T}, node::T, target_index
    )::Tuple{Bool, UInt64} where T

    # shield re-entrance when iterating
    visit!(node, th)

    if node.type == :Core
        if nodevalue(node).logical_index == target_index
            return true, 0
        end
    end

    for child in node.children
        if visited(child, th)
            continue
        end

        found, dist = distance_to_core!(th, child, target_index)
        if found
            return true, dist + 1
        end

    end

    if node.parent != nothing
        found, dist = distance_to_core!(th, node.parent, target_index)
        if found
            return true, dist + 1
        end
    end

    return false, typemax(Int)
end

function distance_to_core(root::T, target_index)::Tuple{Bool, UInt64} where T
    th = TraversalHistory(root)
    return distance_to_core!(th, root, target_index)
end

export distance_to_core

get_nodes(tree_node, type) = filter(
    x->x.type == type,
    collect(PreOrderDFS(tree_node))
)

get_network_devices(root) = filter(
    x->Hwloc.hwloc_pci_class_string(
        nodevalue(x).attr.class_id
    ) == NetworkInterfaceControllers.NICPreferences.hwloc_nic_pci_class,
    get_nodes(root, :PCI_Device)
)

export get_nodes, get_network_devices

end
