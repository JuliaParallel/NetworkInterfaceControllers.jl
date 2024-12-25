module NICPreferences

using Preferences

@enum SELECTION_STRAGETY begin
    PREFERRED_INTERFACE_NAME_MATCH=1
    PREFERRED_INTERFACE_NAME_PREFIX=2
    PRERERRED_INTERFACE_NAME_SUFFIX=3
    PREFERRED_INTERFACE_NAME_REGEX=4
    PREFERRED_INTERFACE_HWLOC_CLOSEST=5
    PREFERRED_INTERFACE_BROKER=6
end

const selection_stragety_str = @load_preference("selection_stragety")
const preferred_interface_name = @load_preference("preferred_interface_name")
const preferred_interface_name_prefix = @load_preference("preferred_interface_name_prefix")
const preferred_interface_name_suffix = @load_preference("preferred_interface_name_suffix")
const preferred_interface_name_regex = @load_preference("preferred_interface_name_regex")

if selection_stragety_str == "name_match"
    const selection_stragety = PREFERRED_INTERFACE_NAME_MATCH
    @assert !isnothing(preferred_interface_name)
elseif selection_stragety_str == "name_prefix"
    const selection_stragety = PREFERRED_INTERFACE_NAME_PREFIX
    @assert !isnothing()
elseif selection_stragety_str == "name_suffix"
    const selection_stragety = PRERERRED_INTERFACE_NAME_SUFFIX
elseif selection_stragety_str == "name_regex"
    const selection_stragety = PREFERRED_INTERFACE_NAME_REGEX
elseif selection_stragety_str == "hwloc_closest"
    const selection_stragety = PREFERRED_INTERFACE_HWLOC_CLOSEST
elseif selection_stragety_str == "broker"
    const selection_straget = PREFERRED_INTERFACE_BROKER
else
    @warn "'selection_stragety' not set to something I can recognize => defaulting to 'name_match'"
    const selection_stragety = PREFERRED_INTERFACE_NAME_MATCH
    @assert !isnothing(preferred_interface_name)
end


function configure(
        selection_strategy;
        preferred_interface_name=nothing,
        preferred_interface_name_prefix=nothing,
        preferred_interface_name_suffix=nothing,
        preferred_interface_name_regex=nothing,
    )

    @assert selection_strategy in [
        "name_match", "name_prefix", "name_suffix", "name_regex",
        "hwloc_clostest", "broker"
    ]

    @set_preferences!(
        "selection_strategy" => selection_strategy,
        "preferred_interface_name" => preferred_interface_name,
        "preferred_interface_name_prefix" => preferred_interface_name_prefix,
        "preferred_interface_name_suffix" => preferred_interface_name_suffix,
        "preferred_interface_name_regex" => preferred_interface_name_regex
    )
end

end
