module Broker

using Sockets
using Serialization

import ..Interfaces

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

function transaction(db::Database, ifd::InterfaceData)::InterfaceAssignment
    selected_interface::String = ""
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
                break
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

function start_server(ip::IPAddr, port::UInt32)
    server::Sockets.TCPServer = listen(ip, port)
    db::Database = Database()

    @debug "Broker service stated with clean DB on $(ip):$(Int(port))"

    while true
        conn = accept(server)
        @async begin
            try
                @debug "Processing connection"
                txn_port::TxnPort = random_free_port(ip)
                serialize(conn, txn_port)
                @debug "Using port $(txn_port) for transaction"
                start_transaction_server(ip, txn_port.port, db)
                @debug "Transaction completed, db=$(db)"
            catch err
                @error "Connection ended with error $(err)."
            end
        end
    end
end

function start_transaction_server(ip::IPAddr, port::UInt32, db::Database)
    # Establish connection on ephermeral port
    @debug "Starting transaction server on: $(ip):$(Int(port))"
    server::Sockets.TCPServer = listen(ip, port)
    conn_txn = accept(server)

    # Get broker request
    @debug "Received incoming connection"
    ifd::InterfaceData = deserialize(conn_txn)
    assignemnt::InterfaceAssignment = transaction(db, ifd)

    # Return interface assignemnt
    @debug "Returning $(assignemnt) from $(ifd)"
    serialize(conn_txn, assignemnt)
    close(conn_txn)
end

function query_broker(
        ip::IPAddr, port::UInt32, interfaces::Vector{Interfaces.Interface};
        max_try=100, timeout=1
    )::InterfaceAssignment
    # Get ephermeral port
    @debug "Querying connection broker on $(ip):$(Int(port))"
    conn_port = connect(ip, port)
    txn_port::TxnPort = deserialize(conn_port)
    close(conn_port)

    # Query broker
    @debug "Trying ephermeral port: $(txn_port.port)"
    conn_txn = Nothing
    for x=1:max_try
        try
            conn_txn = connect(ip, txn_port.port)
        catch e
            if (e isa Base.IOError) && (e.code == -61)
                @debug "Server not ready, retyring"
                sleep(timeout)
            else
                rethrow(e)
            end
        end
        break
    end
    interface_data = InterfaceData(
        gethostname(),
        interfaces |> x->map(y->y.name, x)
    )
    @debug "Sending request: $(interface_data)"
    serialize(conn_txn, interface_data)
    # Get query result
    ifa::InterfaceAssignment = deserialize(conn_txn)
    close(conn_txn)

    @debug "Received $(ifa)"
    return ifa
end

end # module Broker
