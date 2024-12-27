module NetworkInterfaceControllers

include("interfaces.jl")
using .Interfaces
export Interface, get_interface_data

export get_interface_data

include("broker.jl")
using .Broker

include("nic_preferences.jl")
using .NICPreferences

include("name_selector.jl")
using .NameSelector


function best_interface_hwloc_closest(
        data::Interface; pid::Union{T, Nothing}=nothing
    ) where T <: Integer
end

function best_interface_broker(
        data::Interface; broker_port::Union{T, Nothing}=nothing
    ) where T <: Integer
end

function best_interfaces(data::Interface)
    strategy = NICPreferences.selection_strategy

    if strategy == NICPreferences.PREFERRED_INTERFACE_NAME_MATCH
        return NameSelector.best_interfaces(data)
    elseif strategy == NICPreferences.PREFERRED_INTERFACE_HWLOC_CLOSEST
        return best_interface_hwloc_closest(data)
    elseif strategy == NICPreferences.PREFERRED_INTERFACE_BROKER
        return best_interface_broker(data)
    else
        @error "Cannot interpret strategy: $(strategy)"
    end
end


end # module NetworkInterfaces
