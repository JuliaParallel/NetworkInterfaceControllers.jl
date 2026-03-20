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

"""
    get_hwloc_selector()

Return the `HwlocSelector` package extension module, or `nothing` if the
extension has not been loaded. The extension is activated by importing both
`Hwloc` and `AbstractTrees` into the current session, which avoids adding those
packages as hard dependencies.

If your system only has one NUMA domain/PCI bridge then you will have no need
for the HwlocSelector.
"""
get_hwloc_selector() = Base.get_extension(@__MODULE__, :HwlocSelector)

include("hostlists.jl")
using .Hostlists
export Hostlists

#------------------------------------------------------------------------------
# Helper functions for Broker
# These funtions make it easy to set up broker/client pairs in external shells
#------------------------------------------------------------------------------

"""
    julia_runtime_str() -> String

Return a shell-ready string that invokes the current Julia binary with the
active project flag. The resulting string has the form:
```
    <julia_path> --project=<active_project>
```
and is used to construct command-line one-liners that can be executed in
external shells.
"""
function julia_runtime_str()::String
    julia_str   = Base.julia_cmd().exec |> first
    project_str = Base.active_project()
    return "$(julia_str) --project=$(project_str)"
end

"""
    broker_ip_port(ipv::Type{T}) -> Tuple{T, Int64} where T <: IPAddr

Determine the IP address and port on which the broker should listen, according
to the `BROKER_INTERFACE` NIC preferences. The interface is selected by calling
[`get_interface_data`](@ref) for the given IP version `T` (`IPv4` or `IPv6`)
and then narrowing the results with [`NameSelector.best_interfaces`](@ref)
using the configured broker interface name and match strategy. Returns a tuple
`(ip, port)`.

Set:
    1. `NICPreferences.BROKER_INTERFACE.name`, and
    2. `NICPreferences.BROKER_INTERFACE.match_strategy`
to narrow the interface on which to listen. Will fail if it does not narrow to
exactly one result
"""
function broker_ip_port(ipv::Type{T})::Tuple{T, Int64} where T <: IPAddr
    iface = get_interface_data(ipv, loopback=true) |>
            x->NameSelector.best_interfaces(
                x,
                NICPreferences.BROKER_INTERFACE.name,
                NICPreferences.BROKER_INTERFACE.match_strategy
            ) |> only
    return iface.ip, NICPreferences.BROKER_INTERFACE.port
end

"""
    broker_ip_port(ipv::Int) -> Tuple{IPAddr, Int64}

Convenience method that accepts an integer (`4` or `6`) instead of an `IPAddr`
type. Dispatches to `broker_ip_port(IPv4)` or `broker_ip_port(IPv6)`
accordingly.

# Throws
- `AssertionError` if `ipv` is not `4` or `6`.
"""
function broker_ip_port(ipv::Int)::Tuple{IPAddr, Int64}
    @assert ipv in (4, 6)
    protocol = (4==ipv) ? IPv4 : IPv6
    broker_ip_port(protocol)
end

"""
    start_broker(ipv::Type{T}) -> Tuple{T, Int64, Task} where T <: IPAddr

Start the broker server asynchronously for the given IP address type. The
broker address and port are obtained from [`broker_ip_port`](@ref), and
[`Broker.start_server`](@ref) is launched as a scheduled `Task`. Returns `(ip,
port, task)` where `task` can be `wait`ed on to block until the server exits.
"""
function start_broker(ipv::Type{T})::Tuple{T, Int64, Task} where T <: IPAddr
    ip, port = broker_ip_port(ipv)

    t::Task = @task Broker.start_server(ip, UInt32(port))

    # Run the server right away
    schedule(t)
    return ip, port, t
end

"""
    start_broker(ipv::Int) -> Tuple{IPAddr, Int64, Task}

Convenience method that accepts an integer (`4` or `6`) and dispatches to the
corresponding `IPAddr`-typed method.

# Throws
- `AssertionError` if `ipv` is not `4` or `6`.
"""
function start_broker(ipv::Int)::Tuple{IPAddr, Int64, Task}
    @assert ipv in (4, 6)
    protocol = (4==ipv) ? IPv4 : IPv6
    start_broker(protocol)
end

"""
    start_broker()

Start the broker server using IPv4 (the default). Equivalent to
`start_broker(4)`.
"""
start_broker() = start_broker(4)

"""
    broker_ip_string(ipv::Int) -> String

Return a shell command string that, when executed, prints the broker's IP
address for the given IP version (`4` or `6`). The command launches a new Julia
process with the current project and evaluates `broker_ip_port(ipv) |> first`.

# Throws
- `AssertionError` if `ipv` is not `4` or `6`.
"""
function broker_ip_string(ipv::Int)::String
    @assert ipv in (4, 6)

    runtime_str = julia_runtime_str()
    import_str  = "using NetworkInterfaceControllers"
    query_str   = "broker_ip_port($(ipv))"

    return "$(runtime_str) -e '$(import_str); println($(query_str) |> first)'"
end

"""
    broker_ip_string()

Return the shell command string for the broker's IPv4 address. Equivalent to
`broker_ip_string(4)`.
"""
broker_ip_string() = broker_ip_string(4)

"""
    broker_port_string(ipv::Int) -> String

Return a shell command string that, when executed, prints the broker's port
number for the given IP version (`4` or `6`). The command launches a new Julia
process with the current project and evaluates `broker_ip_port(ipv) |> last`.

# Throws
- `AssertionError` if `ipv` is not `4` or `6`.
"""
function broker_port_string(ipv::Int)::String
    @assert ipv in (4, 6)

    runtime_str = julia_runtime_str()
    import_str  = "using NetworkInterfaceControllers"
    query_str   = "broker_ip_port($(ipv))"

    return "$(runtime_str) -e '$(import_str); println($(query_str) |> last)'"
end

"""
    broker_port_string()

Return the shell command string for the broker's IPv4 port. Equivalent to
`broker_port_string(4)`.
"""
broker_port_string() = broker_port_string(4)

@doc raw"""
    broker_startup_string(ipv::Int) -> String

Return a shell command string that, when executed, starts the broker server for
the given IP version (`4` or `6`) and blocks until the server task completes.
Useful for launching the broker from an external terminal or script.

Run 
```
eval "$(julia --project -e 'using NetworkInterfaceControllers; println(broker_startup_string())')"
```
in bash, or 
```
eval (julia --project -e 'using NetworkInterfaceControllers; println(broker_startup_string())')
```
to start a broker on the local machine.

Set the environment variable for debugging information
`JULIA_DEBUG=NetworkInterfaceControllers`

# Throws
- `AssertionError` if `ipv` is not `4` or `6`.
"""
function broker_startup_string(ipv::Int)::String
    @assert ipv in (4, 6)

    runtime_str = julia_runtime_str()
    import_str  = "using NetworkInterfaceControllers"
    query_str   = "start_broker($(ipv))"

    return "$(runtime_str) -e '$(import_str); $(query_str) |> last |> wait'"
end

"""
    broker_startup_string()

Return the shell command string to start the broker with IPv4. Equivalent to
`broker_startup_string(4)`.
"""
broker_startup_string() = broker_startup_string(4)

@doc raw"""
    bash_config(ipv::Int) -> String

Return a Bash `export` statement that sets the broker host environment variable
(the first entry in `NICPreferences.BROKER_HOST_ENV`) to the broker's IP
address for the given IP version (`4` or `6`). The resulting string can be
`eval`-ed in a Bash shell to configure the environment for broker clients.

Run:
```
eval "$(julia --project -e 'using NetworkInterfaceControllers; println(bash_config())')"
```
in bash to configure all environment variables necessary to connect to the
broker. Note tha this won't be necessary if the broker is configured by an
external tool (like Slurm).

Set the environment variable for debugging information
`JULIA_DEBUG=NetworkInterfaceControllers`
"""
function bash_config(ipv::Int)::String
    # Use the first env var in the BROKER_HOST_ENV list to populate the config
    # script -- this will also be the var that best_interface_broker will try
    broker_host_ip_env = NICPreferences.BROKER_HOST_ENV |> first

    broker_host_ip = broker_ip_port(ipv) |> first
    "export $(broker_host_ip_env)=$(broker_host_ip)"
end

"""
    bash_config()

Return the Bash export statement for IPv4. Equivalent to `bash_config(4)`.
"""
bash_config() = bash_config(4)

@doc raw"""
    fish_config(ipv::Int) -> String

Return a Fish shell `set -x` statement that sets the broker host environment
variable (the first entry in `NICPreferences.BROKER_HOST_ENV`) to the broker's
IP address for the given IP version (`4` or `6`). The resulting string can be
`eval`-ed in a Fish shell to configure the environment for broker clients.

Run:
```
eval (julia --project -e 'using NetworkInterfaceControllers; println(fish_config())')
```
in fish to configure all environment variables necessary to connect to the
broker. Note tha this won't be necessary if the broker is configured by an
external tool (like Slurm).

Set the environment variable for debugging information
`JULIA_DEBUG=NetworkInterfaceControllers`
"""
function fish_config(ipv::Int)::String
    # Use the first env var in the BROKER_HOST_ENV list to populate the config
    # script -- this will also be the var that best_interface_broker will try
    broker_host_ip_env = NICPreferences.BROKER_HOST_ENV |> first

    broker_host_ip = broker_ip_port(ipv) |> first
    "set -x $(broker_host_ip_env) $(broker_host_ip)"
end

"""
    fish_config()

Return the Fish shell config statement for IPv4. Equivalent to `fish_config(4)`.
"""
fish_config() = fish_config(4)

export start_broker, broker_ip_port, broker_ip_string, broker_port_string
export broker_startup_string, bash_config, fish_config

#------------------------------------------------------------------------------
# Use broker (possibly hosted elsewhere) to query for the least subscribed
# interface on this machine
#------------------------------------------------------------------------------

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
