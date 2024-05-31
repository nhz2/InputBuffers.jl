module InputBuffers

export InputBuffer

mutable struct InputBuffer{T<:AbstractVector{UInt8}} <: IO
    data::T
    pos::Int64
    size::Int64
    mark::Int64
    opened::Bool
end

"""
    InputBuffer(data::AbstractVector{UInt8}) -> InputBuffer

Create a readable and seekable I/O stream wrapper around a vector of bytes.
"""
function InputBuffer(data::AbstractVector{UInt8})
    InputBuffer{typeof(data)}(data, 0, length(data), -1, true)
end

function Base.close(b::InputBuffer)::Nothing
    b.pos = 0
    b.mark = -1
    b.opened=false
    nothing
end

Base.isopen(b::InputBuffer)::Bool = b.opened
Base.isreadable(b::InputBuffer)::Bool = b.opened
Base.iswritable(b::InputBuffer)::Bool = false

function _throw_closed_error()
    throw(ArgumentError("read failed, InputBuffer is closed"))
end


function Base.eof(b::InputBuffer)::Bool
    isopen(b) || _throw_closed_error()
    b.pos === b.size
end

function Base.position(b::InputBuffer)::Int64
    isopen(b) || _throw_closed_error()
    b.pos
end

function Base.bytesavailable(b::InputBuffer)::Int64
    isopen(b) || _throw_closed_error()
    b.size-b.pos
end

# Seek Operations
# ---------------

function Base.seek(b::InputBuffer, n::Integer)::InputBuffer
    isopen(b) || _throw_closed_error()
    b.pos = clamp(n, 0, b.size)
    b
end

function Base.seekend(b::InputBuffer)::InputBuffer
    isopen(b) || _throw_closed_error()
    b.pos = b.size
    b
end

# Read Functions
# --------------

function Base.read(b::InputBuffer, ::Type{UInt8})::UInt8
    x = peek(b)
    b.pos += 1
    x
end

# needed for `peek(b, Char)` to work
function Base.peek(b::InputBuffer, ::Type{UInt8})::UInt8
    eof(b) && throw(EOFError()) # also prevents overflow and errors if closed
    b.data[firstindex(b.data) + b.pos]
end

function Base.skip(b::InputBuffer, n::Integer)::InputBuffer
    isopen(b) || _throw_closed_error()
    b.pos += clamp(n, -b.pos, b.size - b.pos)
    b
end

function Base.read(b::InputBuffer, nb::Integer = typemax(Int))::Vector{UInt8}
    signbit(nb) && throw(ArgumentError("negative nbytes"))
    out_nb::Int64 = min(nb, bytesavailable(b)) # errors if closed
    out = zeros(UInt8, out_nb)
    copyto!(out, 1, b.data, b.pos+firstindex(b.data), out_nb)
    b.pos += out_nb
    out
end
Base.readavailable(b::InputBuffer) = read(b)

# TODO Benchmark to see if the following are worth implementing
# Base.unsafe_read
# Base.readbytes!
# Base.copyline
# Base.copyuntil

end