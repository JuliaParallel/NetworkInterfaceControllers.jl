module NICPreferences

using Preferences

@enum SELECTION_STRATEGY begin
    PREFERRED_INTERFACE_NAME_MATCH=1
    PREFERRED_INTERFACE_HWLOC_CLOSEST=2
    PREFERRED_INTERFACE_BROKER=3
end

@enum MATCH_STRATEGY begin
    MATCH_EXACT=1
    MATCH_PREFIX=2
    MATCH_SUFFIX=3
    MATCH_REGEX=4
end

const selection_strategy_str = @load_preference("selection_strategy")
const preferred_interface_name = @load_preference("preferred_interface_name")
const interface_name_blacklist = @load_preference("interface_name_blacklist")
const interface_name_whitelist = @load_preference("interface_name_whitelist")
const match_strategy_str = @load_preference("match_strategy")
const hwloc_nic_pci_class = @load_preference("hwloc_nic_pci_class", "Ethernet")

const allowed_selection_stratey_str = [
    "name_match", "hwloc_closest", "broker" 
]
const allowed_match_strategy_str = [
    "exact", "prefix", "suffix", "regex"
]

if !isnothing(selection_strategy_str)
    @assert selection_strategy_str in allowed_selection_stratey_str
end

if selection_strategy_str == "name_match"
    const selection_strategy = PREFERRED_INTERFACE_NAME_MATCH
    @assert !isnothing(preferred_interface_name)
    @assert !isnothing(match_strategy_str)
    @assert match_strategy_str in allowed_match_strategy_str
    if match_strategy_str == "exact"
        const match_strategy = MATCH_EXACT
    elseif match_strategy_str == "prefix"
        const match_strategy = MATCH_PREFIX
    elseif match_strategy_str == "suffix"
        const match_strategy = MATCH_SUFFIX
    elseif match_strategy_str == "regex"
        const match_strategy = MATCH_REGEX
    else
        @error "Could not interpret match match strategy: $(match_strategy_str)"
    end
elseif selection_strategy_str == "hwloc_closest"
    const selection_strategy = PREFERRED_INTERFACE_HWLOC_CLOSEST
elseif selection_strategy_str == "broker"
    const selection_straget = PREFERRED_INTERFACE_BROKER
    @assert !isnothing(preferred_interface_name)
    @assert !isnothing(match_strategy_str)
else
    @warn "'selection_strategy' unrecognized! Defaulting to: PREFERRED_INTERFACE_NAME_MATCH"
    const selection_strategy = PREFERRED_INTERFACE_NAME_MATCH
    const match_strategy = MATCH_EXACT
end


function configure(
        selection_strategy;
        preferred_interface_name=nothing,
        match_strategy=nothing,
        interface_name_whitelist::Union{Vector{String}, Nothing}=nothing,
        interface_name_blacklist::Union{Vector{String}, Nothing}=nothing,
        nic_pci_class::Union{String, Nothing}=nothing
    )

    @assert selection_strategy in allowed_selection_stratey_str

    if selection_strategy == "name_match"
        @assert !isnothing(match_strategy)
        @assert match_strategy in allowed_match_strategy_str
    end

    @set_preferences!(
        "selection_strategy" => selection_strategy,
        "preferred_interface_name" => preferred_interface_name,
        "match_strategy" => match_strategy,
        "interface_name_blacklist" => interface_name_blacklist,
        "interface_name_whitelist" => interface_name_whitelist,
        "hwloc_nic_pci_class" => nic_pci_class
    )
end

end
