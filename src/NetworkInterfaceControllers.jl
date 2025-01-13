module NetworkInterfaceControllers

include("interfaces.jl")
using .Interfaces
export Interface, get_interface_data

export get_interface_data

include("broker.jl")
using .Broker
export start_server, query

include("nic_preferences.jl")
using .NICPreferences

include("name_selector.jl")
using .NameSelector

# Load HwlocSelector module via and extension => avoid adding dependencies on
# Hwloc and AbstractTrees unless needed
get_hwloc_selector() = Base.get_extension(@__MODULE__, :HwlocSelector)

include("hostlists.jl")
using .Hostlists

function start_broker(ipv)
    iface = get_interface_data(ipv, loopback=true) |>
            x->NameSelector.best_interfaces(
                x,
                NICPreferences.BROKER_INTERFACE.name,
                NICPreferences.BROKER_INTERFACE.match_strategy) |>
            only

    t::Task = @task Broker.start_server(
        iface.ip, UInt32(NICPreferences.BROKER_INTERFACE.port)
    )
    # Run the server right away
    schedule(t)
    return iface.ip, NICPreferences.BROKER_INTERFACE.port, t
end

function broker_startup_string(ipv::Int)::String
    @assert ipv in (4, 6)

    julia_str   = Base.julia_cmd().exec |> first
    project_str = Base.active_project()
    import_str  = "using NetworkInterfaceControllers, Sockets"
    query_str = (4==ipv) ? "ip,p,t=start_broker(IPv4)" : "ip,p,t=start_broker(IPv6)"

    return "$(julia_str) --project=$(project_str) -e '$(import_str); $(query_str); println(\"\$(ip):\$(p)\"); wait(t)'"
end

function broker_query_string(ip::String, port::Int)::String
    julia_str   = Base.julia_cmd().exec |> first
    project_str = Base.active_project()
    import_str  = "using NetworkInterfaceControllers.Broker, Sockets"
    query_str   = "Broker.query(ip\"$(ip)\", UInt32($(port)), ifaces)"

    return "$(julia_str) --project=$(project_str) -e '$(import_str); $(query_str)'"
end

export start_broker, broker_startup_string, broker_query_string

function best_interface_hwloc_closest(
        data::Interface; pid::Union{T, Nothing}=nothing
    ) where T <: Integer
end

function best_interface_broker(
        data::Interface; broker_port::Union{T, Nothing}=nothing
    ) where T <: Integer
end

function best_interfaces(data::Vector{Interface})
    strategy = NICPreferences.selection_strategy

    if strategy == NICPreferences.PREFERRED_INTERFACE_NAME_MATCH
        return NameSelector.best_interfaces(data)
    elseif strategy == NICPreferences.PREFERRED_INTERFACE_HWLOC_CLOSEST
        HwlocSelector = get_hwloc_selector()
        if isnothing(HwlocSelector)
            @error "'Hwloc' and/or 'AbstractTrees' not loaded! Run: `import Hwloc, AbstractTrees`"
        end
        return HwlocSelector.best_interfaces(data)
    elseif strategy == NICPreferences.PREFERRED_INTERFACE_BROKER
        return best_interface_broker(data)
    else
        @error "Cannot interpret strategy: $(strategy)"
    end
end


end # module NetworkInterfaces
