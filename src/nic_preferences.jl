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

@enum USE_STRATEGY begin
    USE_ALWAYS=1
    USE_HOSTNAME=2
    USE_DISABLED=3
end

const allowed_mode_keys          = ("when", "hostlist")
const allowed_iface_keys         = ("name", "match_strategy", "port")
const allowed_use_strategy_str   = ("always", "hostname", "never")
const allowed_match_strategy_str = ("exact", "prefix", "suffix", "regex")

check_mode(mode) = issubset(Set(keys(mode)), Set(allowed_mode_keys))
check_interface(iface) = issubset(Set(keys(iface)), Set(allowed_iface_keys))

mutable struct ModeSettings
    when::USE_STRATEGY
    hostlist::Union{Nothing, String}

    function ModeSettings(mode_dict)::ModeSettings
        @assert check_mode(mode_dict)
        @assert "when" in keys(mode_dict)
        @assert mode_dict["when"] in allowed_use_strategy_str

        if "always" == mode_dict["when"]
            when     = USE_ALWAYS
            hostlist = nothing
        elseif "hostname" == mode_dict["when"]
            @assert "hostlist" in keys(mode_dict)
            when     = USE_HOSTNAME
            hostlist = mode_dict["hostlist"]
        elseif "never" == mode_dict["when"]
            when     = USE_DISABLED
            hostlist = nothing
        else
            @error "Cannot interpret: $(mode_dict["when"])"
            when     = nothing
            hostlist = nothing
        end
        return new(when, hostlist)
    end
end

mutable struct InterfaceSettings
    name::Union{Nothing, String}
    match_strategy::MATCH_STRATEGY
    port::Union{Nothing, Int}

    function InterfaceSettings(iface_dict)::InterfaceSettings
        @assert check_interface(iface_dict)
        @assert "name" in keys(iface_dict)
        @assert iface_dict["match_strategy"] in allowed_match_strategy_str

        if "exact" == iface_dict["match_strategy"]
            match_strategy = MATCH_EXACT
        elseif "prefix" == iface_dict["match_strategy"]
            match_strategy = MATCH_PREFIX
        elseif "suffix" == iface_dict["match_strategy"]
            match_strategy = MATCH_SUFFIX
        elseif "regex" == iface_dict["match_strategy"]
            match_strategy = MATCH_REGEX
        else
            @error "Cannot interpret: $(iface_dict["match_strategy"])"
            match_strategy = nothing
        end

        port = ("port" in keys(iface_dict)) ? iface_dict["port"] : nothing

        return new(iface_dict["name"], match_strategy, port)
    end
end

d_mode_always = Dict{String, Any}("when"=>"always")
d_mode_never = Dict{String, Any}("when"=>"never")
d_iface = Dict{String, Any}("name"=>nothing, "match_strategy"=>"exact")
d_iface_broker = Dict{String, Any}("name"=>nothing, "match_strategy"=>"exact", "port"=>1000)
d_class = "Ethernet"

const name_selector_mode = @load_preference("name_selector_mode", deepcopy(d_mode_always))
const preferred_interface = @load_preference("preferred_interface", deepcopy(d_iface))

const INTERFACE_NAME_BLACKLIST = @load_preference("interface_name_blacklist")
const INTERFACE_NAME_WHITELIST = @load_preference("interface_name_whitelist")

const hwloc_selector_mode = @load_preference("hwloc_selector_mode", deepcopy(d_mode_never))
const hwloc_nic_pci_class = @load_preference("hwloc_nic_pci_class", deepcopy(d_class))

const broker_mode = @load_preference("broker_mode", deepcopy(d_mode_never))
const broker_interface = @load_preference("broker_interface_name", deepcopy(d_iface_broker))

const NAME_SELECTOR = ModeSettings(name_selector_mode)
const HWLOC_SELECTOR = ModeSettings(hwloc_selector_mode)
const BROKER = ModeSettings(broker_mode)

const PREFERRED_INTERFACE = InterfaceSettings(preferred_interface)
const BROKER_INTERFACE = InterfaceSettings(broker_interface)

export NAME_SELECTOR, HWLOC_SELECTOR, BROKER
export INTERFACE_NAME_BLACKLIST, INTERFACE_NAME_WHITELIST
export PREFERRED_INTERFACE, BROKER_INTERFACE

function in_list(elt::T, v::Union{Nothing, Vector{T}}, d::Bool)::Bool where T
    isnothing(v) && return d
    return (elt in v)
end

return in_list

function configure(;
        name_selector_mode=d_mode_always,
        preferred_interface=d_iface,
        interface_name_whitelist::Union{Vector{String}, Nothing}=nothing,
        interface_name_blacklist::Union{Vector{String}, Nothing}=nothing,
        hwloc_selector_mode=d_mode_never,
        hwloc_nic_pci_class::Union{String, Nothing}=d_class,
        broker_mode=d_mode_never,
        broker_interface=d_iface_broker
    )

    @assert check_mode(name_selector_mode)
    @assert check_mode(hwloc_selector_mode)
    @assert check_mode(broker_mode)

    @assert check_interface(preferred_interface)
    @assert check_interface(broker_interface)

    @set_preferences!(
        "name_selector_mode" => name_selector_mode,
        "preferred_interface" => preferred_interface,
        "interface_name_whitelist" => interface_name_whitelist,
        "interface_name_blacklist" => interface_name_blacklist,
        "hwloc_selector_mode" => hwloc_selector_mode,
        "hwloc_nic_pci_class" => hwloc_nic_pci_class,
        "broker_mode" => broker_mode,
        "broker_interface" => broker_interface
    )
end

export configure

end
