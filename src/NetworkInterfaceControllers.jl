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

# Load HwlocSelector module via and extension => avoid adding dependencies on
# Hwloc and AbstractTrees unless needed
get_hwloc_selector() = Base.get_extension(@__MODULE__, :HwlocSelector)

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
