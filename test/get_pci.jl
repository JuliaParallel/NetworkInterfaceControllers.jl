using Hwloc, AbstractTrees

x = gettopology()
t = HwlocTreeNode{UInt8}(x)

print_tree(t; maxdepth=10)

function distance_to_core!(node, target_index)
    # shield re-entrance when iterating
    node.tag = 1

    if node.type == :Core
        if nodevalue(node).logical_index == target_index
            return true, 0
        end
    end

    for child in node.children
        if child.tag == 1
            continue
        end

        found, dist = distance_to_core!(child, target_index)
        if found
            return true, dist + 1
        end

    end

    if node.parent != nothing
        found, dist = distance_to_core!(node.parent, target_index)
        if found
            return true, dist + 1
        end
    end

    return false, typemax(Int)
end

function distance_to_core(root, node, target_index)
    Hwloc.tag_subtree!(t, 0) 
    found, dist = distance_to_core!(node, target_index)
    Hwloc.tag_subtree!(t, 0) 
    return found, dist
end

pci_devs = Hwloc.get_nodes(t, :PCI_Device)

network_devs = filter(
    x->Hwloc.hwloc_pci_class_string(nodevalue(x).attr.class_id) == "Ethernet",
    pci_devs
)

println(length(network_devs))

for net in collect(network_devs)
    found, dist = distance_to_core(t, net, 20)
    print("$(dist): ")
    print_tree(net)
end