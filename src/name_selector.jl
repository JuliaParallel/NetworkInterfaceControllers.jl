module NameSelector

import ..Interfaces
import ..NICPreferences

function best_interfaces(
        data::Vector{Interfaces.Interface}, name::String,
        ::Type{Val{NICPreferences.MATCH_EXACT}}
    )
    @debug "Using MATCH_EXACT to find interfaces"
    if isnothing(name)
        @warn "'preferred_interface_name' is empty! Matching to everything"
    end

    matched = Interfaces.Interface[]
    for interface in data
        @debug "Checking: $(interface)"
        if NICPreferences.in_list(
                interface.name, NICPreferences.INTERFACE_NAME_BLACKLIST, false
            )
            @debug "$(interface) is blacklisted => skipping"
            continue
        end

        if ! NICPreferences.in_list(
                interface.name, NICPreferences.INTERFACE_NAME_WHITELIST, true
            )
            @debug "$(interface) is not on (non-empty) whitelist => skipping"
            continue
        end

        if (interface.name == name) || isnothing(name)
            @debug "Found matching interface: $(interface)"
            push!(matched, interface)
        end
    end
    return matched
end

function best_interfaces(
        data::Vector{Interfaces.Interface}, name::String,
        ::Type{Val{NICPreferences.MATCH_PREFIX}}
    )
    @debug "Using MATCH_PREFIX to find interfaces"
    if isnothing(name)
        @warn "'preferred_interface_name' is empty! Matching to everything"
    end

    matched = Interfaces.Interface[]
    for interface in data
        @debug "Checking: $(interface)"
        if NICPreferences.in_list(
                interface.name, NICPreferences.INTERFACE_NAME_BLACKLIST, false
            )
            @debug "$(interface) is blacklisted => skipping"
            continue
        end

        if ! NICPreferences.in_list(
                interface.name, NICPreferences.INTERFACE_NAME_WHITELIST, true
            )
            @debug "$(interface) is not on (non-empty) whitelist => skipping"
            continue
        end

        if startswith(interface.name, name) || isnothing(name)
            @debug "Found matching interface: $(interface)"
            push!(matched, interface)
        end
    end
    return matched
end

function best_interfaces(
        data::Vector{Interfaces.Interface}, name::String,
        ::Type{Val{NICPreferences.MATCH_SUFFIX}}
    )
    @debug "Using MATCH_SUFFIX to find interfaces"
    if isnothing(name)
        @warn "'preferred_interface_name' is empty! Matching to everything"
    end

    matched = Interfaces.Interface[]
    for interface in data
        @debug "Checking: $(interface)"
        if NICPreferences.in_list(
                interface.name, NICPreferences.INTERFACE_NAME_BLACKLIST, false
            )
            @debug "$(interface) is blacklisted => skipping"
            continue
        end

        if ! NICPreferences.in_list(
                interface.name, NICPreferences.INTERFACE_NAME_WHITELIST, true
            )
            @debug "$(interface) is not on (non-empty) whitelist => skipping"
            continue
        end

        if endswith(interface.name, name) || isnothing(name)
            @debug "Found matching interface: $(interface)"
            push!(matched, interface)
        end
    end
    return matched
end

function best_interfaces(
        data::Vector{Interfaces.Interface}, name::String,
        ::Type{Val{NICPreferences.MATCH_REGEX}}
    )
    @debug "Using MATCH_REGEX to find interfaces"

    if isnothing(name)
        @warn "'preferred_interface_name' is empty! Matching to everything"
        name_regex = Regex(".*")
    else
        name_regex = Regex(NICPreferences.PREFERRED_INTERFACE.name)
    end

    matched = Interfaces.Interface[]
    for interface in data
        @debug "Checking: $(interface)"
        if NICPreferences.in_list(
                interface.name, NICPreferences.INTERFACE_NAME_BLACKLIST, false
            )
            @debug "$(interface) is blacklisted => skipping"
            continue
        end

        if ! NICPreferences.in_list(
                interface.name, NICPreferences.INTERFACE_NAME_WHITELIST, true
            )
            @debug "$(interface) is not on (non-empty) whitelist => skipping"
            continue
        end

        if ! isnothing(match(name_regex, interface.name))
            @debug "Found matching interface: $(interface)"
            push!(matched, interface)
        end
    end
    return matched
end

best_interfaces(
    data::Vector{Interfaces.Interface}, name::String,
    v::NICPreferences.MATCH_STRATEGY
) = best_interfaces(data, name, Val{v})

best_interfaces(
    data::Vector{Interfaces.Interface}, v::NICPreferences.MATCH_STRATEGY
) = best_interfaces(data, NICPreferences.PREFERRED_INTERFACE.name, Val{v})

best_interfaces(
    data::Vector{Interfaces.Interface}
) = best_interfaces(data, NICPreferences.PREFERRED_INTERFACE.match_strategy)

end
