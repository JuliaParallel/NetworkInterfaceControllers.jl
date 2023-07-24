# threads_cpuids.jl
using CpuId
function cpuid_coreid()
    eax, ebx, ecx, edx =  CpuId.cpuid(1, 0)
    if ( (edx & (0x00000001 << 9)) == 0x00000000)
        CPU = -1;  # no APIC on chip
    else
        CPU = (ebx%Int) >> 24;
    end
    CPU < 0 ? 0 : CPU
end

glibc_coreid() = @ccall sched_getcpu()::Cint

const cpucycle_mask = (
    (1 << (64 - leading_zeros(CpuId.cputhreads()))) - 1
) % UInt32
# const cpucycle_mask = 0x00000fff
println(cpucycle_mask)
cpucycle_coreid() = Int(cpucycle_id()[2] & cpucycle_mask)

using ThreadPools
using Base.Threads: nthreads

tglibc_coreid(i::Integer) = fetch(@tspawnat i glibc_coreid());
tcpuid_coreid(i::Integer) = fetch(@tspawnat i cpuid_coreid());
tcpucycle_coreid(i::Integer) = fetch(@tspawnat i cpucycle_coreid());

for i in 1:nthreads()
println("Running on thread $i (glibc_coreid: $(tglibc_coreid(i)), cpuid_coreid: $(tcpuid_coreid(i)), cpucycle_coreid: $(tcpucycle_coreid(i)))")
    # @sync @tspawnat i sum(abs2, rand()^2 + rand()^2 for i in 1:500_000_000)
end

