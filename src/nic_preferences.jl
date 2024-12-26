module NICPreferences

using Preferences

@enum SELECTION_STRAGETY begin
    PREFERRED_INTERFACE_NAME_MATCH=1
    PREFERRED_INTERFACE_HWLOC_CLOSEST=2
    PREFERRED_INTERFACE_BROKER=3
end

@enum MATCH_STRAGETY begin
    MATCH_EXACT=1
    MATCH_PREFIX=2
    MATCH_SUFFIX=3
    MATCH_PREFIX_SUFFIX=4
    MATCH_REGEX=5
end

const selection_stragety_str = @load_preference("selection_strategy")
const preferred_interface_name = @load_preference("preferred_interface_name")
const interface_name_blacklist = @load_preference("interface_name_blacklist")
const interface_name_whitelist = @load_preference("interface_name_whitelist")
const match_stragety_str = @load_preference("match_stragety")

const allowed_selection_stratey_str = [
    "name_match", "hwloc_closest", "broker" 
]
const allowed_match_strategy_str = [
    "exact", "prefix", "suffix", "prefix_suffix", "regex"
]

if !isnothing(selection_stragety_str)
    @assert selection_stragety_str in allowed_selection_stratey_str
end

if selection_stragety_str == "name_match"
    const selection_stragety = PREFERRED_INTERFACE_NAME_MATCH
    @assert !isnothing(preferred_interface_name)
    @assert !isnothing(match_stragety_str)
    @assert match_stragety_str in allowed_match_strategy_str
    if match_stragety_str == "exact"
        const match_strategy = MATCH_EXACT
    elseif match_stragety_str == "prefix"
        const match_stragety = MATCH_PREFIX
    elseif match_stragety_str == "suffix"
        const match_stragety = MATCH_SUFFIX
    elseif match_stragety_str == "prefix_suffix"
        const match_stragety = MATCH_PREFIX_SUFFIX
    elseif match_stragety_str == "regex"
        const match_stragety = MATCH_REGEX
    else
        @error "Could not interpret match match strategy: $(match_stragety_str)"
    end
elseif selection_stragety_str == "hwloc_closest"
    const selection_stragety = PREFERRED_INTERFACE_HWLOC_CLOSEST
elseif selection_stragety_str == "broker"
    const selection_straget = PREFERRED_INTERFACE_BROKER
    @assert !isnothing(preferred_interface_name)
    @assert !isnothing(match_stragety_str)
else
    @warn "'selection_stragety' not set to something I can recognize => defaulting to exact name match"
    const selection_stragety = PREFERRED_INTERFACE_NAME_MATCH
    const match_stragety = MATCH_EXACT
    @assert !isnothing(preferred_interface_name)
end


function configure(
        selection_strategy;
        preferred_interface_name=nothing,
        match_stragety=nothing,
        interface_name_whitelist::Union{Vector{String}, Nothing}=nothing,
        interface_name_blacklist::Union{Vector{String}, Nothing}=nothing
    )

    @assert selection_strategy in allowed_selection_stratey_str

    if selection_strategy == "name_match"
        @assert !isnothing(match_stragety)
        @assert match_stragety in allowed_match_strategy_str
    end

    @set_preferences!(
        "selection_strategy" => selection_strategy,
        "preferred_interface_name" => preferred_interface_name,
        "match_stragety" => match_stragety,
        "interface_name_blacklist" => interface_name_blacklist,
        "interface_name_whitelist" => interface_name_whitelist
    )
end

end
