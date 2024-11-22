import Test: @testset, @test

import NetworkInterfaceControllers: get_interface_data


@testset "get_interface_data()" begin
    interfaces = get_interface_data(; loopback=true)
    # We should always see at least the loopback interface
    @test !isempty(interfaces)
end
