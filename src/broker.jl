module Broker

using Sockets
using Serialization


struct TxnPort
    port::UInt32
end

struct InterfaceData
    hostname::String
    interfaces::Vector{String}
end

struct InterfaceAssignment
    interface::String
end

struct Database
    usage::Dict{String, Dict{String, UInt64}}
    lock::ReentrantLock

    function Database()
        new(
            Dict{String, Dict{String, UInt64}}(),
            ReentrantLock()
        )
    end
end


function transaction(db::Database, ifd::InterfaceData)
    selected_interface::String
    lock(db.lock) do
        # We'll be iterating over these interfaces only -- this way the ifd
        # interface list can be used to select valid interfaces
        hostname   = ifd.hostname
        interfaces = ifd.interfaces

        # If no preexisting entry => create one in the db
        if !(hostname in keys(db.usage))
            db.usage[hostname] = Dict{String, UInt64}()
            for interface in ifd.interfaces
                db.usage[hostname][interface] = 0
            end
        end

        # We'll be working on this entry ...
        host_entry = db.usage[hostname]

        # Check the database entry if all the interfaces are recorded. Iterate
        # over the ifd interfaces only; the search for the least-used interface
        # only considers the ifd interface list
        for interface in interfaces
            if !(interface in keys(host_entry))
                host_entry[interface] = 0
            end
        end

        # Find the first interface that has the lowest count. Iterate over the
        # ifd interface list only; this is a feature allowing the user to
        # whitelist which interfaces to choose from
        lowest_count = typemax(UInt64)
        for interface in interfaces
            if lowest_count > host_entry[interface]
                lowest_count = host_entry[interface]
            end
        end
        # Once we have the lowest interface usage count, we select whichever
        # interface has that lowest count and we come accross first -- yay!
        for interface in interfaces
            if lowest_count == host_entry[interface]
                host_entry[interface] += 1
                selected_interface = interface
            end
        end
    end
    return InterfaceAssignment(selected_interface)
end


function random_free_port(ip::IPv4; start=1000, stop=61000, max_attempts=100)
    for _ in 1:max_attempts
        port::UInt32 = rand(start:stop)
        try
            server::Sockets.TCPServer = listen(ip, port)
            close(server)

            @debug "Found free port $(ip):$(Int32(port))"
            return TxnPort(port)
        catch e
            @debug "$(e); For $(ip):$(Int32(port)), trying another..."

        end
    end
    @error "Could not find a free port after $(max_attempts) attempts."
end


function start_listener(ip::IPv4, port::UInt32)
    server::TCPServer = listen(ip, port)

    while true
        conn = accept(server)
        print(typeof(conn))

        @async begin
            try
                while true
                    txn_port::TxnPort = random_free_port(ip)
                    line::IOBuffer    = IOBuffer()
                    serialize(line, txn_port)
                    seekstart(line)
                    write(conn, line)
                end
            catch err
                @error "Connection ended with error $(err)."
            end
        end
    end
end


function start_transaction(ip::IPv4, port::UInt32)

end


end # module Broker
