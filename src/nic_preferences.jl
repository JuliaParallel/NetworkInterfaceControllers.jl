module NICPreferences

using Preferences

const preferred_interface_name = @load_preference("preferred_interface_name")

end
