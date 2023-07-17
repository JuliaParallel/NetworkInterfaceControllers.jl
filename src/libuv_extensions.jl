module LibUVExtensions


##
#
# These functions are generated from Julia's LibUV
# (https://github.com/libuv/libuv) using Clang.jl -- taking only those functions
# needed by this module
#
# Note: _Some_ of Julia's LibUV prefixes uv_* symbols with jl_*. Eg.:
# uv_interface_addresses becomes: jl_uv_interface_addresses
# (but not all!)
#
##


using CEnum

const sa_family_t = Cushort

const in_port_t = UInt16

const in_addr_t = UInt32

struct in_addr
    s_addr::in_addr_t
end

struct sockaddr_in
    sin_family::sa_family_t
    sin_port::in_port_t
    sin_addr::in_addr
    sin_zero::NTuple{8, Cuchar}
end

struct sockaddr_in6
    data::NTuple{28, UInt8}
end

function Base.getproperty(x::Ptr{sockaddr_in6}, f::Symbol)
    f === :sin6_family && return Ptr{sa_family_t}(x + 0)
    f === :sin6_port && return Ptr{in_port_t}(x + 2)
    f === :sin6_flowinfo && return Ptr{UInt32}(x + 4)
    f === :sin6_addr && return Ptr{in6_addr}(x + 8)
    f === :sin6_scope_id && return Ptr{UInt32}(x + 24)
    return getfield(x, f)
end

function Base.getproperty(x::sockaddr_in6, f::Symbol)
    r = Ref{sockaddr_in6}(x)
    ptr = Base.unsafe_convert(Ptr{sockaddr_in6}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{sockaddr_in6}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct var"##Ctag#362"
    data::NTuple{28, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#362"}, f::Symbol)
    f === :address4 && return Ptr{sockaddr_in}(x + 0)
    f === :address6 && return Ptr{sockaddr_in6}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#362", f::Symbol)
    r = Ref{var"##Ctag#362"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#362"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#362"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct var"##Ctag#363"
    data::NTuple{28, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#363"}, f::Symbol)
    f === :netmask4 && return Ptr{sockaddr_in}(x + 0)
    f === :netmask6 && return Ptr{sockaddr_in6}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#363", f::Symbol)
    r = Ref{var"##Ctag#363"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#363"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#363"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct uv_interface_address_s
    data::NTuple{80, UInt8}
end

function Base.getproperty(x::Ptr{uv_interface_address_s}, f::Symbol)
    f === :name && return Ptr{Ptr{Cchar}}(x + 0)
    f === :phys_addr && return Ptr{NTuple{6, Cchar}}(x + 8)
    f === :is_internal && return Ptr{Cint}(x + 16)
    f === :address && return Ptr{var"##Ctag#362"}(x + 20)
    f === :netmask && return Ptr{var"##Ctag#363"}(x + 48)
    return getfield(x, f)
end

function Base.getproperty(x::uv_interface_address_s, f::Symbol)
    r = Ref{uv_interface_address_s}(x)
    ptr = Base.unsafe_convert(Ptr{uv_interface_address_s}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{uv_interface_address_s}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

const uv_interface_address_t = uv_interface_address_s

function uv_interface_addresses(addresses, count)
    ccall(:jl_uv_interface_addresses, Cint, (Ptr{Ptr{uv_interface_address_t}}, Ptr{Cint}), addresses, count)
end

function uv_free_interface_addresses(addresses, count)
    ccall(:uv_free_interface_addresses, Cvoid, (Ptr{uv_interface_address_t}, Cint), addresses, count)
end

end