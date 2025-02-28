module Interfaces
using Base: unsafe_convert, RefValue
using Sockets


include("libuv_extensions.jl")
using .LibUVExtensions:
    uv_interface_address_t, uv_interface_addresses, uv_free_interface_addresses


const _sizeof_uv_interface_address = ccall(
    :jl_uv_sizeof_interface_address, Int32, ()
)

function _next(r::RefValue{Ptr{uv_interface_address_t}})
    Ref(
        unsafe_convert(
            Ptr{uv_interface_address_t},
            unsafe_convert(Ptr{UInt8}, r[]) + _sizeof_uv_interface_address
        )
    )
end

_is_loopback(addr::Ptr{uv_interface_address_t}) = 1 == ccall(
    :jl_uv_interface_address_is_internal,
    Int32, (Ptr{uv_interface_address_t},),
    addr
)

_sockaddr(addr::Ptr{uv_interface_address_t}) = ccall(
    :jl_uv_interface_address_sockaddr,
    Ptr{Cvoid}, (Ptr{UInt8},),
    addr
)

function _iface_name(addr::Ptr{uv_interface_address_t})
    r = unsafe_load(addr)
    GC.@preserve r unsafe_string(r.name)
end

_sockaddr_is_ip4(sockaddr::Ptr{Cvoid}) = 1 == ccall(
    :jl_sockaddr_is_ip4,
    Int32, (Ptr{Cvoid},),
    sockaddr
)

_sockaddr_is_ip6(sockaddr::Ptr{Cvoid}) = 1 == ccall(
    :jl_sockaddr_is_ip6,
    Int32, (Ptr{Cvoid},),
    sockaddr
)

_sockaddr_to_ip4(sockaddr::Ptr{Cvoid}) = IPv4(
    ntoh(ccall(:jl_sockaddr_host4, UInt32, (Ptr{Cvoid},), sockaddr))
)

function _sockaddr_to_ip6(sockaddr::Ptr{Cvoid}) 
    addr6 = Ref{UInt128}()
    ccall(
        :jl_sockaddr_host6,
        UInt32, (Ptr{Cvoid}, Ref{UInt128},),
        sockaddr, addr6
    )
    IPv6(ntoh(addr6[]))
end

struct Interface
    name::String
    version::Symbol
    ip::IPAddr
end

function get_interface_data(
    ::Type{T}=IPAddr; loopback::Bool=false
) where T <: IPAddr

    addr_ref  = Ref{Ptr{uv_interface_address_t}}(C_NULL)
    count_ref = Ref{Int32}(1)

    err = uv_interface_addresses(addr_ref, count_ref)
    @assert err == 0

    interface_data = Interface[]
    current_addr = addr_ref
    for i = 0:(count_ref[]-1)
        @debug "Scanning interface $(i)"
        # Skip loopback devices, if so required
        if (!loopback) && _is_loopback(current_addr[])
            # Don't don't forget to iterate the address pointer though!
            current_addr = _next(current_addr)
            @debug "Interface $(i) is a loopback device => skipping"
            continue
        end

        # Interface name string
        name = _iface_name(current_addr[])

        # Sockaddr used to load IPv4, or IPv6 addresses
        sockaddr = _sockaddr(current_addr[])

        # Load IP addresses
        (ip_type, ip_address) = if IPv4 <: T && _sockaddr_is_ip4(sockaddr)
            (:v4, _sockaddr_to_ip4(sockaddr))
        elseif IPv6 <: T && _sockaddr_is_ip6(sockaddr)
            (:v6, _sockaddr_to_ip6(sockaddr))
        else
            (:skip, nothing)
        end

        @debug "Interface $(i) is called '$(name)' at IP: $(ip_address)"

        # Append to data vector and itnerate address pointer
        if ip_type != :skip
            push!(interface_data, Interface(name, ip_type, ip_address))
        end
        current_addr = _next(current_addr)
    end

    uv_free_interface_addresses(addr_ref[], count_ref[])

    return interface_data
end

export Interface, get_interface_data
end
