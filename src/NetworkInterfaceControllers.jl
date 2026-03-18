module NetworkInterfaceControllers

using Sockets

include("interfaces.jl")
using .Interfaces
export Interface, get_interface_data

export get_interface_data

include("broker.jl")
using .Broker
export Broker
export start_server, query_broker

include("nic_preferences.jl")
using .NICPreferences
export NICPreferences

include("name_selector.jl")
using .NameSelector
export NameSelector

# Load HwlocSelector module via and extension => avoid adding dependencies on
# Hwloc and AbstractTrees unless needed
get_hwloc_selector() = Base.get_extension(@__MODULE__, :HwlocSelector)

include("hostlists.jl")
using .Hostlists
export Hostlists

#------------------------------------------------------------------------------
# Helper functions for Broker
# These funtions make it easy to set up broker/client pairs in external shells
#------------------------------------------------------------------------------

function julia_runtime_str()::String
    julia_str   = Base.julia_cmd().exec |> first
    project_str = Base.active_project()
    return "$(julia_str) --project=$(project_str)"
end

function broker_ip_port(ipv::Type{T})::Tuple{T, Int64} where T <: IPAddr
    iface = get_interface_data(ipv, loopback=true) |>
            x->NameSelector.best_interfaces(
                x,
                NICPreferences.BROKER_INTERFACE.name,
                NICPreferences.BROKER_INTERFACE.match_strategy
            ) |> only
    return iface.ip, NICPreferences.BROKER_INTERFACE.port
end

function broker_ip_port(ipv::Int)::Tuple{IPAddr, Int64}
    @assert ipv in (4, 6)
    protocol = (4==ipv) ? IPv4 : IPv6
    broker_ip_port(protocol)
end

function start_broker(ipv::Type{T})::Tuple{T, Int64, Task} where T <: IPAddr
    ip, port = broker_ip_port(ipv)

    t::Task = @task Broker.start_server(ip, UInt32(port))

    # Run the server right away
    schedule(t)
    return ip, port, t
end

function start_broker(ipv::Int)::Tuple{IPAddr, Int64, Task}
    @assert ipv in (4, 6)
    protocol = (4==ipv) ? IPv4 : IPv6
    start_broker(protocol)
end

start_broker() = start_broker(4)

function broker_ip_string(ipv::Int)::String
    @assert ipv in (4, 6)

    runtime_str = julia_runtime_str()
    import_str  = "using NetworkInterfaceControllers"
    query_str   = "broker_ip_port($(ipv))"

    return "$(runtime_str) -e '$(import_str); println($(query_str) |> first)'"
end

broker_ip_string() = broker_ip_string(4)

function broker_port_string(ipv::Int)::String
    @assert ipv in (4, 6)

    runtime_str = julia_runtime_str()
    import_str  = "using NetworkInterfaceControllers"
    query_str   = "broker_ip_port($(ipv))"

    return "$(runtime_str) -e '$(import_str); println($(query_str) |> last)'"
end

broker_port_string() = broker_port_string(4)

function broker_startup_string(ipv::Int)::String
    @assert ipv in (4, 6)

    runtime_str = julia_runtime_str()
    import_str  = "using NetworkInterfaceControllers"
    query_str   = "start_broker($(ipv))"

    return "$(runtime_str) -e '$(import_str); $(query_str) |> last |> wait'"
end

broker_startup_string() = broker_startup_string(4)

function bash_config(ipv::Int)::String
    # Use the first env var in the BROKER_HOST_ENV list to populate the config
    # script -- this will also be the var that best_interface_broker will try
    broker_host_ip_env = NICPreferences.BROKER_HOST_ENV |> first

    broker_host_ip = broker_ip_port(ipv) |> first
    "export $(broker_host_ip_env)=$(broker_host_ip)"
end

bash_config() = bash_config(4)

function fish_config(ipv::Int)::String
    # Use the first env var in the BROKER_HOST_ENV list to populate the config
    # script -- this will also be the var that best_interface_broker will try
    broker_host_ip_env = NICPreferences.BROKER_HOST_ENV |> first

    broker_host_ip = broker_ip_port(ipv) |> first
    "set -x $(broker_host_ip_env) $(broker_host_ip)"
end

fish_config() = fish_config(4)

export start_broker, broker_ip_port, broker_ip_string, broker_port_string
export broker_startup_string, bash_config, fish_config



function best_interface_broker(
        data::Vector{Interface}, ipv::Type{V};
        broker_port::Union{T, Nothing}=nothing
    ) where {T <: Integer, V <: IPAddr}

    if isnothing(broker_port)
        @debug "Getting broker port from NICPreferences.BROKER_INTERFACE"
        broker_port = NICPreferences.BROKER_INTERFACE.port
        @assert !isnothing(broker_port)
    end

    # Default to `localhost` if a suitable environment variable containing the
    # broker address is not set
    broker_addr        = "localhost"
    broker_addr_source = "default"
    for broker_addr_source in NICPreferences.BROKER_HOST_ENV
        if broker_addr_source in keys(ENV)
            broker_addr = ENV[broker_addr_source]
            @debug (
                "'$(broker_addr_source)' found in environment => ",
                "using '$(broker_addr)' as broker address hostlist"
            )
            break # break on first occurrence
        end
    end

    # Interpret broker_addr as a hostlist
    broker_addr = Hostlists.HOSTLIST_TYPE[](broker_addr) |> first
    @debug (
        "Using broker server address = '$(broker_addr)' ",
        "(from `ENV[$(broker_addr_source)]`)"
    )

    ip, port = broker_ip_port(ipv)
    return Broker.query_broker(ip, UInt32(port), data)
end

function best_interfaces(data::Vector{Interface})
    strategy = NICPreferences.selection_strategy

    if strategy == NICPreferences.PREFERRED_INTERFACE_NAME_MATCH
        return NameSelector.best_interfaces(data)
    elseif strategy == NICPreferences.PREFERRED_INTERFACE_HWLOC_CLOSEST
        HwlocSelector = get_hwloc_selector()
        if isnothing(HwlocSelector)
            @error (
                "'Hwloc' and/or 'AbstractTrees' not loaded! ",
                "Run: `import Hwloc, AbstractTrees`"
            )
        end
        return HwlocSelector.best_interfaces(data)
    elseif strategy == NICPreferences.PREFERRED_INTERFACE_BROKER
        return best_interface_broker(data)
    else
        @error "Cannot interpret strategy: $(strategy)"
    end
end


end # module NetworkInterfaces
