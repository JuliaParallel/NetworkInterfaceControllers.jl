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

function best_interfaces(
        data::Vector{Interfaces.Interface},
        ::Type{Val{NICPreferences.MATCH_EXACT}}
    )
    @debug "Using MATCH_EXACT to find interfaces"
    if isnothing(NICPreferences.preferred_interface_name)
        @warn "'preferred_interface_name' is empty! Matching to everything"
    end

    matched = Interfaces.Interface[]
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

        if interface.name == NICPreferences.preferred_interface_name ||
        isnothing(NICPreferences.preferred_interface_name)
            @debug "Found matching interface: $(interface)"
            push!(matched, interface)
        end
    end
    return matched
end

function best_interfaces(
        data::Vector{Interfaces.Interface},
        ::Type{Val{NICPreferences.MATCH_PREFIX}}
    )
    @debug "Using MATCH_PREFIX to find interfaces"
    if isnothing(NICPreferences.preferred_interface_name)
        @warn "'preferred_interface_name' is empty! Matching to everything"
    end

    matched = Interfaces.Interface[]
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

        if startswith(interface.name, NICPreferences.preferred_interface_name) ||
        isnothing(NICPreferences.preferred_interface_name)
            @debug "Found matching interface: $(interface)"
            push!(matched, interface)
        end
    end
    return matched
end

function best_interfaces(
        data::Vector{Interfaces.Interface},
        ::Type{Val{NICPreferences.MATCH_SUFFIX}}
    )
    @debug "Using MATCH_SUFFIX to find interfaces"
    if isnothing(NICPreferences.preferred_interface_name)
        @warn "'preferred_interface_name' is empty! Matching to everything"
    end

    matched = Interfaces.Interface[]
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

        if endswith(interface.name, NICPreferences.preferred_interface_name) ||
        isnothing(NICPreferences.preferred_interface_name)
            @debug "Found matching interface: $(interface)"
            push!(matched, interface)
        end
    end
    return matched
end

function best_interfaces(
        data::Vector{Interfaces.Interface},
        ::Type{Val{NICPreferences.MATCH_REGEX}}
    )
    @debug "Using MATCH_REGEX to find interfaces"

    if isnothing(NICPreferences.preferred_interface_name)
        @warn "'preferred_interface_name' is empty! Matching to everything"
        name_regex = Regex(".*")
    else
        name_regex = Regex(NICPreferences.preferred_interface_name)
    end

    matched = Interfaces.Interface[]
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

        if !isnothing(match(name_regex, interface.name))
            @debug "Found matching interface: $(interface)"
            push!(matched, interface)
        end
    end
    return matched
end

best_interfaces(
    data::Vector{Interfaces.Interface}, v::NICPreferences.MATCH_STRATEGY
) = best_interfaces(data, Val{v})

best_interfaces(
    data::Vector{Interfaces.Interface}
) = best_interfaces(data, NICPreferences.match_strategy)

end
