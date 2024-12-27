module NameSelector

import ..Interfaces
import ..NICPreferences


function check_whitelist(data::Interfaces.Interface)
    if isnothing(NICPreferences.interface_name_whitelist)
        return true
    end

    if length(NICPreferences.interface_name_whitelist) == 0
        return true
    end

    data in NICPreferences.interface_name_whitelist
end


function best_interface(
        data::Vector{Interfaces.Interface},
        ::Type{Val{NICPreferences.MATCH_EXACT}}
    )
    @debug "Using MATCH_EXACT to find interfaces"
    if isnothing(NICPreferences.preferred_interface_name)
        @warn "'preferred_interface_name' is empty! Returning first interface"
        return data |> first
    end

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

        if interface.name == NICPreferences.preferred_interface_name
            @debug "Found matching interface: $(interface)"
            return interface
        end
    end
end


best_interface(
    data::Vector{Interfaces.Interface}, v::NICPreferences.MATCH_STRATEGY
) = best_interface(data, Val{v})


function best_interface(data::Vector{Interfaces.Interface})
    strategy = NICPreferences.match_strategy
end

end
