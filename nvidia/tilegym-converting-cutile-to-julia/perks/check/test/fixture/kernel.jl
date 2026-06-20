import cuTile as ct
using CUDA

# Minimal clean cuTile.jl kernel — no Python-to-Julia anti-patterns.
# 1D element-wise add with alpha scaling (Julia is 1-indexed, broadcast dot).
function add_kernel(a::ct.TileArray, b::ct.TileArray, out::ct.TileArray, alpha)
    i = ct.bid(1)
    ta = ct.load(a, i)
    tb = ct.load(b, i)
    tc = ta .+ alpha .* tb
    ct.store(out, i, tc)
    return nothing
end
