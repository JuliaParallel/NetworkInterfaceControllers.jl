def _split-feature-list [s] {
    if ($s == null or $s == "" or $s == "(null)") {
        []
    } else {
        $s
        | split row ","
        | each {|x| $x | str trim }
        | where {|x| $x != "" }
    }
}

# One row per grouped Slurm nodelist, with available + active feature lists.
# This is the cheapest useful primitive to build from.
def slurm-node-features [] {
    ^sinfo -h -e -o "%N|%f|%b"
    | from csv --separator '|' --noheaders
    | rename nodelist available_features active_features
    | update available_features {|row| _split-feature-list $row.available_features }
    | update active_features {|row| _split-feature-list $row.active_features }
}

# Invert the mapping into: feature -> Slurm hostlist
# By default this uses AvailableFeatures; pass --active for ActiveFeatures.
#
# The hostlist column is still a valid Slurm hostlist expression, so you can
# pass it directly to srun/scontrol/etc.
def slurm-feature-hostlists [
    --active (-a)
] {
    let col = if $active { "active_features" } else { "available_features" }

    slurm-node-features
    | each {|row|
            ($row | get $col)
            | each {|feat| { feature: $feat, nodelist: $row.nodelist } }
        }
    | flatten
    | group-by feature
    | transpose feature rows
    | each {|g|
            {
                feature: $g.feature
                hostlist: ($g.rows | get nodelist | uniq | str join ",")
            }
        }
    | sort-by feature
}

# Expand one feature's hostlist to individual nodes only when you actually need it.
def slurm-feature-nodes [
    feature: string,
    --active (-a)
] {
    let tbl = if $active {
        slurm-feature-hostlists --active
    } else {
        slurm-feature-hostlists
    }

    let hostlist = (
        $tbl
        | where feature == $feature
        | get hostlist
        | first
    )

    ^scontrol show hostnames $hostlist | lines
}
