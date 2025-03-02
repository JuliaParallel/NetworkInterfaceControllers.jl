module NICPreferences

using Preferences

@enum MATCH_STRATEGY begin
    MATCH_EXACT=1
    MATCH_PREFIX=2
    MATCH_SUFFIX=3
    MATCH_REGEX=4
end

export MATCH_EXACT, MATCH_PREFIX, MATCH_SUFFIX, MATCH_REGEX, MATCH_STRATEGY

@enum USE_STRATEGY begin
    USE_ALWAYS=1
    USE_HOSTNAME=2
    USE_DISABLED=3
end

export USE_ALWAYS, USE_HOSTNAME, USE_DISABLED, USE_STRATEGY

const allowed_mode_keys          = ("when", "hostlist")
const allowed_iface_keys         = ("name", "match_strategy", "port")
const allowed_use_strategy_str   = ("always", "hostname", "never")
const allowed_match_strategy_str = ("exact", "prefix", "suffix", "regex")

check_mode(mode) = issubset(Set(keys(mode)), Set(allowed_mode_keys))
check_interface(iface) = issubset(Set(keys(iface)), Set(allowed_iface_keys))

function mode_dict(
        when::USE_STRATEGY, hostname::Union{String, Nothing}=nothing
    )::Dict{String, Any}

    md = Dict{String, Any}()

    if when == USE_ALWAYS
        md["when"] = "always"
    elseif when == USE_HOSTNAME
        md["when"] = "hostname"
    elseif when == USE_DISABLED
        md["when"] = "never"
    else
        @error "$(when) is unhandled"
    end

    !isnothing(hostname) && (md["hostname"] = hostname)

    if !check_mode(md)
        @error "$(md) is not a valid mode dict"
    end

    return md
end

function iface_dict(
        name::Union{String, Nothing}, match_strategy::MATCH_STRATEGY,
        port::Union{Int, Nothing}=nothing
    )::Dict{String, Any}

    ifd = Dict{String, Any}()

    ifd["name"] = name

    if match_strategy == MATCH_EXACT
        ifd["match_strategy"] = "exact"
    elseif match_strategy == MATCH_PREFIX
        ifd["match_strategy"] = "prefix"
    elseif match_strategy == MATCH_SUFFIX
        ifd["match_strategy"] = "suffix"
    elseif match_strategy == MATCH_REGEX
        ifd["match_strategy"] = "regex"
    else
        @error "$(match_strategy) is unhandled"
    end

    !isnothing(port) && (ifd["port"] = port)

    if !check_interface(ifd)
        @error "$(ifd) is not a valid interface dict"
    end

    return ifd
end

setting(::Val{:mode}, args...; kwargs...) = mode_dict(args...; kwargs...)
setting(::Val{:interface}, args...; kwargs...) = iface_dict(args...; kwargs...)
setting(s::Symbol, args...; kwargs...) = setting(Val(s), args...; kwargs...)

export setting


macro val_or_default(s)
    return :( isnothing(eval($s)) ? eval(Symbol($s, :_default)) : eval($s) )
end

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

        return new(get(iface_dict, "name", nothing), match_strategy, port)
    end
end


const _name_selector_mode_default = setting(:mode, USE_ALWAYS)
const _preferred_interface_default = setting(:interface, ".*", MATCH_REGEX)
const _name_selector_mode = @load_preference("name_selector_mode")
const _preferred_interface = @load_preference("preferred_interface")

const INTERFACE_NAME_BLACKLIST = @load_preference("interface_name_blacklist")
const INTERFACE_NAME_WHITELIST = @load_preference("interface_name_whitelist")

const _hwloc_selector_mode_default = setting(:mode, USE_DISABLED)
const _hwloc_nic_pci_class_default = "Ethernet"
const _hwloc_selector_mode = @load_preference("hwloc_selector_mode")
const HWLOC_NIC_PCI_CLASS = @load_preference(
    "hwloc_nic_pci_class", _hwloc_nic_pci_class_default
)

const _broker_mode_default = setting(:mode, USE_DISABLED)
const _broker_interface_default = setting(:interface, ".*", MATCH_REGEX, 3000)
const _broker_mode = @load_preference("broker_mode")
const _broker_interface = @load_preference("broker_interface")
const BORKER_HOST_ENV = @load_preference("broker_host_env")

const NAME_SELECTOR = ModeSettings(@val_or_default(:_name_selector_mode))
const HWLOC_SELECTOR = ModeSettings(@val_or_default(:_hwloc_selector_mode))
const BROKER = ModeSettings(@val_or_default(:_broker_mode))

const PREFERRED_INTERFACE = InterfaceSettings(@val_or_default(:_preferred_interface))
const BROKER_INTERFACE = InterfaceSettings(@val_or_default(:_broker_interface))

export NAME_SELECTOR, HWLOC_SELECTOR, BROKER
export INTERFACE_NAME_BLACKLIST, INTERFACE_NAME_WHITELIST
export PREFERRED_INTERFACE, BROKER_INTERFACE
export HWLOC_NIC_PCI_CLASS

function in_list(elt::T, v::Union{Nothing, Vector{T}}, d::Bool)::Bool where T
    isnothing(v) && return d
    return (elt in v)
end

return in_list

function configure!(;
        name_selector_mode::Dict{String, Any}=_name_selector_mode_default,
        preferred_interface::Dict{String, Any}=_preferred_interface_default,
        interface_name_whitelist::Union{Vector{String}, Nothing}=nothing,
        interface_name_blacklist::Union{Vector{String}, Nothing}=nothing,
        hwloc_selector_mode::Dict{String, Any}=_hwloc_selector_mode_default,
        hwloc_nic_pci_class::Union{String, Nothing}=_hwloc_nic_pci_class_default,
        broker_mode::Dict{String, Any}=_broker_mode_default,
        broker_interface::Dict{String, Any}=_broker_interface_default,
        broker_host_env::Union{Vector{String}, Nothing}=nothing
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
        "broker_interface" => broker_interface,
        "broker_host_env" => broker_host_env
    )
end

export configure

end
