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

    function Database()
        new(Dict{String, Dict{String, UInt64}}())
    end
end


function random_free_port(start=1000, stop=61000, max_attempts=100)
    for _ in 1:max_attempts
        port::Int32 = rand(start:stop)
        try
            # TODO: make inter address configurable
            server::Sockets.TCPServer = listen(port)
            close(server)

            @debug "Found free port at: $(Int32(port))"
            return TxnPort(port)
        catch e
            @debug "Error $(e); Port $(Int32(port)) is busy, trying another..."

        end
    end
    error("Could not find a free port after $max_attempts attempts.")
end


function start_listener(port)
    # TODO: make inter address configurable
    server::TCPServer = listen(port)

    while true
        conn = accept(server)
        print(typeof(conn))

        @async begin
            try
                while true
                    txn_port::TxnPort = random_free_port()
                    line::IOBuffer    = IOBuffer()
                    serialize(line, txn_port)
                    seekstart(line)
                    write(conn, line)
                end
            catch err
                print("connection ended with error $err")
            end
        end
    end
end


function start_transaction(port)

end


end # module Broker
