module NameSelector

import ..Interfaces
import ..NICPreferences

function best_interface(data::Interfaces.Interface)
    strategy = NICPreferences.match_strategy
end

end
