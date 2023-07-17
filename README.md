# NetworkInterfaces.jl
Extensions to Julia's LibUV to help with working with multiple NICs per node.

## Methods

1. `get_interface_data(<:IPAddr; loopback=false)` returns IP addresses, versions, and interface names of all connected interfaces. Eg:
```julia
julia> using NetworkInterfaces,Sockets
julia> get_interface_data(IPv4)
1-element Vector{NetworkInterfaces.Interface}:
 NetworkInterfaces.Interface("wlp114s0", :v4, ip"192.168.100.64")
```
Helpful when multiple NICs are connected to a node, and you want to find the IP address corresponding to a specific NIC
