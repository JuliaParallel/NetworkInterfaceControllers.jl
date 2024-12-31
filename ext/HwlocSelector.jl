module HwlocSelector

using Hwloc, AbstractTrees, NetworkInterfaceControllers

struct TraversalHistory{T}
    distance::IdDict{T, Int}

    function TraversalHistory(root::T) where T
        distance = IdDict{T, Int}()
        for c in PreOrderDFS(root)
            distance[c] = -1
        end
        new{T}(distance)
    end
end

Base.getindex(th::TraversalHistory{T}, k::T) where T = th.distance[k]
Base.setindex!(th::TraversalHistory{T}, v::Int, k::T) where T = th.distance[k] = v
Base.keys(th::TraversalHistory{T}) where T = keys(th.distance)

function visit!(node::T, dist::Int, history::TraversalHistory{T})::Int where T
    if !visited(node, history)
        history[node] = dist
        return dist
    end

    history[node] = minimum((history[node], dist))
    return history[node]
end

function visited(node::T, history::TraversalHistory{T})::Bool where T
    return history[node] > 0
end

function reset(history::TraversalHistory{T})::Nothing where T
    for k in keys(history)
        history[k] = -1
    end
    return nothing
end

function get_cpu_id(pid=getpid())::Int
    topo = Hwloc.topology_init() 
    ierr = Hwloc.LibHwloc.hwloc_topology_load(topo)
    @assert ierr == 0

    bm = Hwloc.LibHwloc.hwloc_bitmap_alloc()

    Hwloc.LibHwloc.hwloc_get_proc_last_cpu_location(
        topo, pid, bm, Hwloc.LibHwloc.HWLOC_CPUBIND_THREAD
    )
    cpu_id = Hwloc.LibHwloc.hwloc_bitmap_first(bm)
    @debug "Hwloc CPU ID: $(cpu_id)"

    Hwloc.LibHwloc.hwloc_bitmap_free(bm)
    Hwloc.LibHwloc.hwloc_topology_destroy(topo)

    return cpu_id
end

export get_cpu_id

function distance_to_core!(
        th::TraversalHistory{T}, dist::Int, node::T, target_index
    )::Tuple{Bool, Int} where T

    # save current distance when iterating -- if already visited, return the
    # minimal distance
    dist = visit!(node, dist, th)

    if node.type == :PU
        if nodevalue(node).os_index == target_index
            return true, dist
        end
    end

    for child in node.children
        visited(child, th) && continue

        found, dist = distance_to_core!(th, dist + 1, child, target_index)
        found && return true, dist
    end

    if !isnothing(node.parent)
        found, dist = distance_to_core!(th, dist + 1, node.parent, target_index)
        found && return true, dist
    end

    return false, dist 
end

function distance_to_core(root::T, node::T, target_index)::Tuple{Bool, Int} where T
    th = TraversalHistory(root)
    return distance_to_core!(th, 0, node, target_index)
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

function hwloc_nic_name(pci_device)
    os_device = pci_device |> x->get_nodes(x, :OS_Device) |> only
    os_device |> nodevalue |> x->getfield(x, :name)
end

export get_nodes, get_network_devices

function hwloc_nic_distances(cpuid::Int)::Dict{String, Int}
    topo = children(gettopology())
    net  = get_network_devices(topo) |> collect

    distances = Dict{String, Int}()
    for n in net
        name = hwloc_nic_name(n)
        found, dist = distance_to_core(topo, n, cpuid)
        if found
            distances[name] = dist
            @debug "Interface $(name) is $(dist) steps from cpu $(cpuid)"
        else
            @warn "Failed to find path connecting interface $(name) with cpu $(cpuid) on Hwloc tree"
        end
    end

    return distances
end

function best_interfaces(
        data::Vector{NetworkInterfaceControllers.Interface},
        ::Type{Val{NetworkInterfaceControllers.NICPreferences.MATCH_EXACT}}
    )
    @debug "Using MATCH_EXACT to find interfaces"
    if isnothing(NICPreferences.preferred_interface_name)
        @warn "'preferred_interface_name' is empty! Matching to everything"
    end

    matched = Interfaces.Interface[]
    for interface in data
        @debug "Checking: $(interface)"
        if interface in NICPreferences.interface_name_blacklist
            @debug "$(interface) is blacklisted => skipping"
            continue
        end

        if !check_whitelist(interface)
            @debug "$(interface) is not on (non-empty )whitelist => skipping"
            continue
        end

        if interface.name == NICPreferences.preferred_interface_name ||
        isnothing(NICPreferences.preferred_interface_name)
            @debug "Found matching interface: $(interface)"
            push!(matched, interface)
        end
    end
    return matched
end

export hwloc_nic_distances

end
