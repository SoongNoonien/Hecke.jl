
#function image_func(M::Map)
#  return M.header.image
#end
#
#function preim_func(M::Map)
#  return M.header.preim
#end

function show(io::IO, M::Map)
  print(io, "Map with following data\n")
  print(io, "Domain:\n")
  print(io, "=======\n")
  print(io, "$(domain(M))\n\n")
  print(io, "Codomain:\n")
  print(io, "=========\n")
  print(io, "$(codomain(M))\n")
end

function preimage(M::Map, a)
  if isdefined(M.header, :preimage)
    p = M.header.preimage(a)#::elem_type(D)
    @assert parent(p) == domain(M)
    return p
  end
  error("No preimage function known")
end

function image{D, C}(M::Map{D, C}, a)
  if isdefined(M.header, :image)
    return M.header.image(a)::elem_type(C)
  else
    error("No image function known")
  end
end

function show(io::IO, M::InverseMap)
  println(io, "inverse of")
  println(io, " ", M.origin)
end

function inv(a::Map)
  return InverseMap(a)
end

function show(io::IO, M::CoerceMap)
  println(io, "Coerce: $(domain(M)) -> $(codomain(M))")
end

\(f::Map, x) = preimage(f, x)


