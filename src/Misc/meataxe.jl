export meataxe, composition_factors, composition_series, submodules, maximal_submodules, minimal_submodules

add_assert_scope(:MeatAxe)
####################################################################
#
#  Tools for MeatAxe
#
#####################################################################

#
# Given a matrix $M$ in echelon form and a vector, it returns
# the vector reduced with respect to $M$
#
function cleanvect(M::T, v::T) where {T}
  @assert nrows(v)==1
  w=deepcopy(v)
  if iszero(v)
    return w  
  end
  for i=1:nrows(M)
    if iszero_row(M,i)
      continue
    end
    ind=1
    while M[i,ind]==0
      ind+=1
    end
    if iszero(w[1,ind])
      continue
    end
    mult=divexact(w[1,ind], M[i,ind])
    w[1,ind]=parent(M[1,1])(0)
    for k=ind+1:ncols(M)
      w[1,k]-= mult*M[i,k]
    end      
  end
  return w

end

#
#  Given a matrix C containing the coordinates of vectors v_1,dots, v_k 
#  in echelon form, the function computes a basis for the submodule they generate
# 

function closure(C::T, G::Array{T,1}) where {T}
  rref!(C)
  i=1
  while i <= nrows(C)
    w=view(C, i:i, 1:ncols(C))
    for j=1:length(G)
      res=cleanvect(C,w*G[j])
      if !iszero(res)
        C=vcat(C,res)  
        if nrows(C)==ncols(C)
          i=ncols(C)+1
          break
        end
      end 
    end  
    i+=1
  end
  r = rref!(C)
  if r != nrows(C)
    C = sub(C, 1:r, 1:ncols(C))
  end
  return C
end

#
#  Given a matrix C containing the coordinates of vectors v_1,dots, v_k,
#  the function computes a basis for the submodule they generate
# 

function spinning(C::T,G::Array{T,1}) where {T}

  B=deepcopy(C)
  X=rref(C)[2]
  i=1
  while i != nrows(B)+1
    for j=1:length(G)
      el= view(B, i:i, 1:ncols(B)) * G[j]
      res= cleanvect(X,el)
      if !iszero(res)
        X=vcat(X,res)
        rref!(X)
        B=vcat(B,el)
        if nrows(B)==ncols(B)
          return B
        end
      end
    end  
    i+=1
  end
  return B
  
end

#
#  Function to obtain the action of G on the quotient and on the submodule
#

function clean_and_quotient(M::T,N::T, pivotindex::Set{Int}) where {T}

  coeff=zero_matrix(parent(M[1,1]),nrows(N),nrows(M))
  for i=1:nrows(N)
    for j=1:nrows(M)
      if iszero_row(M,j)
        continue
      end
      ind=1
      while iszero(M[j,ind])
        ind+=1
      end
      coeff[i,j]=divexact(N[i,ind], M[j,ind])
      for s=1:ncols(N)
        N[i,s]-=coeff[i,j]*M[j,s]
      end
    end
  end 
  vec= zero_matrix(parent(M[1,1]),nrows(N),ncols(M)-length(pivotindex))
  for i=1:nrows(N)  
    pos=0
    for s=1:ncols(M)
      if !(s in pivotindex)
        pos+=1
        vec[i,pos]=N[i,s]
      end 
    end
  end
  return coeff, vec
end

#
#  Restriction of the action to the submodule generated by C and the quotient
#

function _split(C::fq_nmod_mat,G::Array{fq_nmod_mat,1})
# I am assuming that C is a Fp[G]-submodule

  equot=Array{fq_nmod_mat,1}(undef, length(G))
  esub=Array{fq_nmod_mat,1}(undef, length(G))
  pivotindex=Set{Int}()
  for i=1:nrows(C)
    ind=1
    while iszero(C[i,ind])
      ind+=1
    end
    push!(pivotindex,ind)   
  end
  for a=1:length(G)
    subm,vec=clean_and_quotient(C, C*G[a],pivotindex)
    esub[a]=subm
    s=zero_matrix(parent(C[1,1]),ncols(G[1])-length(pivotindex),ncols(G[1])-length(pivotindex))
    pos=0
    for i=1:nrows(G[1])
      if !(i in pivotindex)
        m,vec=clean_and_quotient(C,sub(G[a],i:i,1:nrows(G[1])),pivotindex)
        for j=1:ncols(vec)
          s[i-pos,j]=vec[1,j]
        end
      else 
        pos+=1
      end
    end
    equot[a]=s
  end
  return FqGModule(esub),FqGModule(equot),pivotindex

end

#
#  Restriction of the action to the submodule generated by C
#

function actsub(C::fq_nmod_mat,G::Array{fq_nmod_mat,1})

  esub=Array{fq_nmod_mat,1}(undef, length(G))
  pivotindex=Set{Int}()
  for i=1:nrows(C)
    ind=1
    while iszero(C[i,ind])
      ind+=1
    end
    push!(pivotindex,ind)   
  end
  for a=1:length(G)
    subm,vec=clean_and_quotient(C, C*G[a],pivotindex)
    esub[a]=subm
  end
  return FqGModule(esub)
end

#
#  Restriction of the action to the quotient by the submodule generated by C
#

function actquo(C::fq_nmod_mat,G::Array{fq_nmod_mat,1})

  equot=Array{fq_nmod_mat,1}(undef, length(G))
  pivotindex=Set{Int}()
  for i=1:nrows(C)
    ind=1
    while iszero(C[i,ind])
      ind+=1
    end
    push!(pivotindex,ind)   
  end
  for a=1:length(G)
    s=zero_matrix(parent(C[1,1]),ncols(G[1])-length(pivotindex),ncols(G[1])-length(pivotindex))
    pos=0
    for i=1:nrows(G[1])
      if !(i in pivotindex)
        m,vec=clean_and_quotient(C,sub(G[a],i:i,1:nrows(G[1])),pivotindex)
        for j=1:ncols(vec)
          s[i-pos,j]=vec[1,j]
        end
      else 
        pos+=1
      end
    end
    equot[a]=s
  end
  return FqGModule(equot), pivotindex
  
end


#
#  Function that determine if two G-modules are isomorphic, provided that the first is irreducible
#

function isisomorphic(M::FqGModule,N::FqGModule)
  
  @assert M.isirreducible
  @assert M.K==N.K
  @assert length(M.G)==length(N.G)
  if M.dim!=N.dim
    return false
  end

  if M.dim==1
    return M.G==N.G
  end

  K=M.K
  Kx,x=PolynomialRing(K, "x", cached=false)
  
  if length(M.G)==1
    f=charpoly(Kx,M.G[1])
    g=charpoly(Kx,N.G[1])
    if f==g
      return true
    else
      return false
    end
  end
  
  #n=M.dim
  #posfac=n
   
  #f=Kx(1)
  #G=deepcopy(M.G)
  #H=deepcopy(N.G)

  rel=_relations(M,N)
  return iszero(rel[N.dim, N.dim])

  #=
  
  #
  #  Adding generators to obtain randomness
  #
  
  for i=1:max(length(M.G),9)
    l1=rand(1:length(G))
    l2=rand(1:length(G))
    while l1 !=l2
      l2=rand(1:length(G))
    end
    push!(G, G[l1]*G[l2])
    push!(H, H[l1]*H[l2])
  end

  #
  #  Now, we get peakwords
  #
  
  A=zero_matrix(K,n,n)
  B=zero_matrix(K,n,n)
  found=false
  
  while !found
  
    A=zero_matrix(K,n,n)
    B=zero_matrix(K,n,n)
    l1=rand(1:length(G))
    l2=rand(1:length(G))
    push!(G, G[l1]*G[l2])
    push!(H, H[l1]*H[l2])
  
    for i=1:length(G)
      s=rand(K)
      A+=s*G[i]
      B+=s*H[i]
    end
  
    cp=charpoly(Kx,A)
    cpB=charpoly(Kx,B)
    if cp!=cpB
      return false
    end
    sq=prod(collect(keys(factor_squarefree(cp).fac)))
    j=1
    while !isone(sq)
      g=gcd(x^(Int(order(K)^j))-x,sq)
      sq=divexact(sq,g)
      lf=factor(g)
      for t in keys(lf.fac)
        f=t
        S=_subst(t,A)
        a,kerA=nullspace(transpose(S))
        if a==1
          M.dim_spl_fld=1
          found=true
          break
        end
        kerA=transpose(kerA)
        posfac=gcd(posfac,a) 
        if divisible(fmpz(posfac),a)
          v=sub(kerA, 1:1, 1:n)
          U=v
          T =spinning(v,G)
          G1=[T*mat*inv(T) for mat in M.G]
          i=2
          E=fq_nmod_mat[eye(T,a)]
          while nrows(U)!= a
            w= sub(kerA, i:i, 1:n)
            z= cleanvect(U,w)
            if iszero(z)
              continue
            end
            O =spinning(w,G)
            G2=[O*mat*inv(O) for mat in M.G]
            if G1 == G2
              b=kerA*O
              x=transpose(solve(transpose(kerA),transpose(b)))
              push!(E,x)
              U=vcat(U,z)
              U=closure(U,E)
            else 
              break
            end
            if nrows(U)==a
              M.dim_spl_fld=a
              found=true
              break
            else
              i+=1
            end
          end
        end
        if found==true
          break
        end
      end   
      j+=1        
    end
  end
  #
  #  Get the standard basis
  #

  
  L=_subst(f,A)
  a,kerA=nullspace(transpose(L))
  
  I=_subst(f,B)
  b,kerB=nullspace(transpose(I))


  if a!=b
    return false
  end
  
  Q= spinning(transpose(sub(kerA, 1:n, 1:1)), M.G)
  W= spinning(transpose(sub(kerB, 1:n, 1:1)), N.G)
  
  #
  #  Check if the actions are conjugated
  #
  S=inv(W)*Q
  T=inv(S)
  for i=1:length(M.G)
    if S*M.G[i]* T != N.G[i]
      return false
    end
  end
  return true

  =#
end


#function _solve_unique(A::fq_nmod_mat, B::fq_nmod_mat)
#  X = zero_matrix(base_ring(A), ncols(B), nrows(A))
#
#  #println("solving\n $A \n = $B * X")
#  r, per, L, U = lu(B) # P*M1 = L*U
#  inv!(per)  
#  @assert B == per*L*U
#
#  Ap = inv(per)*A
#  Y = similar(A)
#
#  #println("first solve\n $Ap = $L * Y")
#
#  for i in 1:ncols(Y)
#    for j in 1:nrows(Y)
#      s = Ap[j, i]
#      for k in 1:j-1
#        s = s - Y[k, i]*L[j, k]
#      end
#      Y[j, i] = s
#    end
#  end
#
#  @assert Ap == L*Y
#
#  #println("solving \n $Y \n = $U * X")
#
#  YY = sub(Y, 1:r, 1:ncols(Y))
#  UU = sub(U, 1:r, 1:r)
#  X = inv(UU)*YY
#
#  @assert Y == U * X
#
#  @assert B*X == A
#  return X
#end

function dual_space(M::FqGModule)
  
  G=fq_nmod_mat[transpose(g) for g in M.G]
  return FqGModule(G)

end

#function _subst(f::Nemo.PolyElem{T}, a::fq_nmod_mat) where {T <: Nemo.RingElement}
#   #S = parent(a)
#   n = degree(f)
#   if n < 0
#      return similar(a)#S()
#   elseif n == 0
#      return coeff(f, 0)*eye(a)
#   elseif n == 1
#      return coeff(f, 0)*eye(a) + coeff(f, 1)*a
#   end
#   d1 = isqrt(n)
#   d = div(n, d1)
#   A = powers(a, d)
#   s = coeff(f, d1*d)*A[1]
#   for j = 1:min(n - d1*d, d - 1)
#      c = coeff(f, d1*d + j)
#      if !iszero(c)
#         s += c*A[j + 1]
#      end
#   end
#   for i = 1:d1
#      s *= A[d + 1]
#      s += coeff(f, (d1 - i)*d)*A[1]
#      for j = 1:min(n - (d1 - i)*d, d - 1)
#         c = coeff(f, (d1 - i)*d + j)
#         if !iszero(c)
#            s += c*A[j + 1]
#         end
#      end
#   end
#   return s
#end

#################################################################
#
#  MeatAxe, Composition Factors and Composition Series
#
#################################################################



@doc Markdown.doc"""
***
    meataxe(M::FqGModule) -> Bool, MatElem

> Given module M, returns true if the module is irreducible (and the identity matrix) and false if the space is reducible, togheter with a basis of a submodule

"""

function meataxe(M::FqGModule)

  K=M.K
  Kx,x=PolynomialRing( K,"x", cached=false)
  n=M.dim
  H=M.G
  if M.dim==1
    M.isirreducible=true
    return true, identity_matrix(base_ring(H[1]), n)
  end
  
  if length(H)==1
    A=H[1]
    poly=charpoly(Kx,A)
    sq=factor_squarefree(poly)
    lf=factor(first(keys(sq.fac)))
    t=first(keys(lf.fac))
    if degree(t)==n
      M.isirreducible=true
      return true, identity_matrix(base_ring(H[1]), n)
    else 
      N= _subst(t, A)
      kern=transpose(nullspace(transpose(N))[2])
      B=closure(sub(kern,1:1, 1:n),H)
      return false, B
    end
  end
  
  #
  #  Adding generators to obtain randomness
  #
  G=deepcopy(H)
  Gt=fq_nmod_mat[transpose(x) for x in M.G]
  
  for i=1:max(length(M.G),9)
    l1=rand(1:length(G))
    l2=rand(1:length(G))
    while l1 !=l2
      l2=rand(1:length(G))
    end
    push!(G, G[l1]*G[l2])
  end
  
  
  while true
  
  # At every step, we add a generator to the group.
  
    push!(G, G[rand(1:length(G))]*G[rand(1:length(G))])
    
  #
  # Choose a random combination of the actual generators of G
  #
    A=zero_matrix(K,n,n)
    for i=1:length(G)
      add!(A, A, rand(K)*G[i])
    end
 
  #
  # Compute the characteristic polynomial and, for irreducible factor f, try the Norton test
  # 
    poly=charpoly(Kx,A)
    sqfpart=keys(factor_squarefree(poly).fac)
    for el in sqfpart
      sq=el
      i=1
      while !isone(sq)
        f=gcd(powmod(x, order(K)^i, sq)-x,sq)
        sq=divexact(sq,f)
        lf=factor(f)
        for t in keys(lf.fac)
          N = _subst(t, A)
          a,kern=nullspace(transpose(N))
          #
          #  Norton test
          #   
          B=closure(transpose(view(kern,1:n, 1:1)),M.G)
          if nrows(B)!=n
            M.isirreducible=false
            return false, B
          end
          kernt=nullspace(N)[2]
          Bt=closure(transpose(view(kernt,1:n,1:1)),Gt)
          if nrows(Bt)!=n
            subst=transpose(nullspace(Bt)[2])
            @assert nrows(subst)==nrows(closure(subst,G))
            M.isirreducible=false
            return false, subst
          end
          if degree(t)==a
            #
            # f is a good factor, irreducibility!
            #
            M.isirreducible=true
            return true, identity_matrix(base_ring(G[1]), n)
          end
        end
        i+=1
      end
    end
  end
end

@doc Markdown.doc"""
***
    composition_series(M::FqGModule) -> Array{MatElem,1}

> Given a Fq[G]-module M, it returns a composition series for M, i.e. a sequence of submodules such that the quotient of two consecutive element is irreducible.

"""

function composition_series(M::FqGModule)

  if isdefined(M, :isirreducible) && M.isirreducible==true
    return [identity_matrix(base_ring(M.G[1]), M.dim)]
  end

  bool, C = meataxe(M)
  #
  #  If the module is irreducible, we return a basis of the space
  #
  if bool == true
    return [identity_matrix(base_ring(M.G[1]), M.dim)]
  end
  #
  #  The module is reducible, so we call the algorithm on the quotient and on the subgroup
  #
  G=M.G
  K=M.K
  
  rref!(C)
  
  esub,equot,pivotindex=_split(C,G)
  sub_list = composition_series(esub)
  quot_list = composition_series(equot)
  #
  #  Now, we have to write the submodules of the quotient and of the submodule in terms of our basis
  #
  list=Array{fq_nmod_mat,1}(undef, length(sub_list)+length(quot_list))
  for i=1:length(sub_list)
    list[i]=sub_list[i]*C
  end
  for z=1:length(quot_list)
    s=zero_matrix(K,nrows(quot_list[z]), ncols(C))
    for i=1:nrows(quot_list[z])
      pos=0
      for j=1:ncols(C)
        if j in pivotindex
          pos+=1
        else
          s[i,j]=quot_list[z][i,j-pos]
        end
      end
    end
    list[length(sub_list)+z]=vcat(C,s)
  end
  return list
end

@doc Markdown.doc"""
***
    composition_factors(M::FqGModule)

> Given a Fq[G]-module M, it returns, up to isomorphism, the composition factors of M with their multiplicity,
> i.e. the isomorphism classes of modules appearing in a composition series of M

"""

function composition_factors(M::FqGModule; dimension::Int=-1)
  
  if isdefined(M, :isirreducible) && M.isirreducible
    if dimension!= -1 
      if M.dim==dimension
        return Tuple{FqGModule, Int}[(M,1)]
      else
        return Tuple{FqGModule, Int}[]
      end
    else
      return Tuple{FqGModule, Int}[(M,1)]
    end
  end 
 
  K=M.K::FqNmodFiniteField
  
  bool, C = meataxe(M)
  #
  #  If the module is irreducible, we just return a basis of the space
  #
  if bool
    if dimension!= -1 
      if M.dim==dimension
        return Tuple{FqGModule, Int}[(M,1)]
      else
        return Tuple{FqGModule, Int}[]
      end
    else
      return Tuple{FqGModule, Int}[(M,1)]
    end
  end
  G=M.G
  #
  #  The module is reducible, so we call the algorithm on the quotient and on the subgroup
  #
  
  rref!(C)
  
  sub,quot,pivotindex=_split(C,G)
  sub_list = composition_factors(sub)
  quot_list = composition_factors(quot)
  #
  #  Now, we check if the factors are isomorphic
  #

  for i=1:length(sub_list)
    for j=1:length(quot_list)
      if isisomorphic(sub_list[i][1], quot_list[j][1])
        sub_list[i]=(sub_list[i][1], sub_list[i][2]+quot_list[j][2])
        deleteat!(quot_list,j)
        break
      end    
    end
  end
  return append!(sub_list, quot_list) 
  #=
  for i=1:length(sub_list)
    for j=1:length(quot_list)
      if isisomorphic(sub_list[i][1], quot_list[j][1])
        sub_list[i][2]+=quot_list[j][2]
        deleteat!(quot_list,j)
        break
      end    
    end
  end
  return append!(sub_list,quot_list)
  =#
end



function _relations(M::FqGModule, N::FqGModule)

  @assert M.isirreducible
  G=M.G
  H=N.G
  K=M.K
  n=M.dim
  
  sys=zero_matrix(K,2*N.dim,N.dim)
  matrices=fq_nmod_mat[]
  first=true
  B=zero_matrix(K,1,M.dim)
  B[1,1]=K(1)
  X=B
  push!(matrices, identity_matrix(base_ring(B), N.dim))
  i=1
  while i<=nrows(B)
    w=view(B, i:i, 1:n)
    for j=1:length(G)
      v=w*G[j]
      res=cleanvect(X,v)
      if !iszero(res)
        X=rref(vcat(X,v))[2]
        B=vcat(B,v)
        push!(matrices, matrices[i]*H[j])
      else
        x=_solve_unique(transpose(v),transpose(B))
        A = matrices[i]*H[j]
        for q = 1:nrows(x)
          for s = 1:N.dim
            for t = 1:N.dim
              A[s, t] -= x[q, 1]* matrices[q][s,t]
            end
          end
        end
        if first
          for s=1:N.dim
            for t=1:N.dim
              sys[s,t]=A[t,s]
            end
          end
          first=false
        else
          for s=1:N.dim
            for t=1:N.dim
              sys[N.dim+s,t]=A[t,s]
            end
          end
        end
        rref!(sys)
      end
    end
    if sys[N.dim,N.dim]!=0
      break
    end
    i=i+1
  end
  return sys
end

function _irrsubs(M::FqGModule, N::FqGModule)

  @assert M.isirreducible
  
  K=M.K
  rel=_relations(M,N)
  if rel[N.dim, N.dim]!=0
    return fq_nmod_mat[]
  end
  a,kern=nullspace(rel)
  kern=transpose(kern)
  if a==1
    return fq_nmod_mat[closure(kern, N.G)]
  end 
  vects=fq_nmod_mat[view(kern, i:i, 1:N.dim) for i=1:a]
 
  #
  #  Try all the possibilities. (A recursive approach? I don't know if it is a smart idea...)
  #  Notice that we eliminate lots of candidates considering the action of the group on the homomorphisms space
  #
  candidate_comb=append!(_enum_el(K,[K(0)], length(vects)-1),_enum_el(K,[K(1)],length(vects)-1))
  deleteat!(candidate_comb,1)
  list=Array{fq_nmod_mat,1}(undef, length(candidate_comb))
  for j=1:length(candidate_comb)
    list[j] = sum([candidate_comb[j][i]*vects[i] for i=1:length(vects)])
  end
  final_list=fq_nmod_mat[]
  push!(final_list, closure(list[1], N.G))
  for i = 2:length(list)
    reduce=true
    for j=1:length(final_list)      
      w=cleanvect(final_list[j],list[i])
      if iszero(w)
        reduce=false
        break
      end
    end  
    if reduce
      push!(final_list, closure(list[i],N.G))
    end
  end
  return final_list

end

@doc Markdown.doc"""
***
    minimal_submodules(M::FqGModule)

> Given a Fq[G]-module M, it returns all the minimal submodules of M

"""


function minimal_submodules(M::FqGModule, dim::Int=M.dim+1, lf=[])
  
  K=M.K
  n=M.dim
  
  if M.isirreducible==true
    return fq_nmod_mat[]
  end

  list=fq_nmod_mat[]
  if isempty(lf)
    lf=composition_factors(M)
  end
  if length(lf)==1 && lf[1][2]==1
    return fq_nmod_mat[]
  end
  if dim!=n+1
    lf=[x for x in lf if x[1].dim==dim]
  end
  if isempty(lf)
    return list
  end
  G=M.G
  for x in lf
    append!(list,Hecke._irrsubs(x[1],M)) 
  end
  return list
end


@doc Markdown.doc"""
***
    maximal_submodules(M::FqGModule)

> Given a $G$-module $M$, it returns all the maximal submodules of M

"""
function maximal_submodules(M::FqGModule, index::Int=M.dim, lf=[])

  M_dual=dual_space(M)
  minlist=minimal_submodules(M_dual, index+1, lf)
  maxlist=Array{fq_nmod_mat,1}(undef, length(minlist))
  for j=1:length(minlist)
    maxlist[j]=transpose(nullspace(minlist[j])[2])
  end
  return maxlist

end

@doc Markdown.doc"""
***
    submodules(M::FqGModule)

> Given a $G$-module $M$, it returns all the submodules of M

"""
function submodules(M::FqGModule)

  K=M.K
  list = fq_nmod_mat[]
  lf = composition_factors(M)
  minlist = minimal_submodules(M, M.dim+1, lf)
  for x in minlist
    rref!(x)
    N, pivotindex = actquo(x,M.G)
    ls=submodules(N)
    for a in ls
      s=zero_matrix(K,nrows(a), M.dim)
      for t=1:nrows(a)
        pos=0
        for j=1:M.dim
          if j in pivotindex
            pos+=1
          else
            s[t,j]=a[t,j-pos]
          end
        end
      end
      push!(list,vcat(x,s))
    end
  end
  for x in list
    rref!(x)
  end
  i=2
  while i<length(list)
    j=i+1
    while j<=length(list)
      if nrows(list[j])!=nrows(list[i])
        j+=1
      elseif list[j]==list[i]
        deleteat!(list, j)
      else 
        j+=1
      end
    end
    i+=1
  end
  append!(list,minlist)
  push!(list, zero_matrix(K, 0, M.dim))
  push!(list, identity_matrix(K, M.dim))
  return list
end


@doc Markdown.doc"""
***
    submodules(M::FqGModule, index::Int)

> Given a $G$-module $M$, it returns all the submodules of M of index q^index, where q is the order of the field

"""
function submodules(M::FqGModule, index::Int; comp_factors=Tuple{FqGModule, Int}[])
  
  K=M.K
  if index==M.dim
    return fq_nmod_mat[zero_matrix(K,1,M.dim)]
  end
  list=fq_nmod_mat[]
  if index>= M.dim/2
    if index== M.dim -1
      if isempty(comp_factors)
        lf=composition_factors(M, dimension=1)
      else
        lf=comp_factors
      end
      list=minimal_submodules(M,1,lf)
      return list
    end
    if isempty(comp_factors)
      lf=composition_factors(M)
    else 
      lf=comp_factors
    end
    for i=1: M.dim-index-1
      minlist=minimal_submodules(M,i,lf)
      for x in minlist
        N, pivotindex= actquo(x, M.G)
        #
        #  Recover the composition factors of the quotient
        #
        Sub=actsub(x, M.G)
        lf1=[(x[1], x[2]) for x in lf]
        for j=1:length(lf1)
          if isisomorphic(lf1[j][1], Sub)
            if lf1[j][2]==1
              deleteat!(lf1,j)
            else
              lf1[j]=(lf1[j][1], lf1[j][2]-1)
            end
            break
          end
        end
        #
        #  Recursively ask for submodules and write their bases in terms of the given set of generators
        #
        ls=submodules(N,index, comp_factors=lf1)
        for a in ls
          s=zero_matrix(K,nrows(a)+nrows(x), M.dim)
          for t=1:nrows(a)
            pos=0
            for j=1:M.dim
              if j in pivotindex
               pos+=1
             else
               s[t,j]=a[t,j-pos]
              end
            end
          end
          for t=nrows(a)+1:nrows(s)
            for j=1:ncols(s)
              s[t,j]=x[t-nrows(a),j]
            end
          end
          push!(list,s)
        end
      end
    end
   
  #
  #  Eliminating repeatitions
  #

    for x in list
      rref!(x)
    end
    i=1
    while i<=length(list)
      k=i+1
      while k<=length(list)
        if list[i]==list[k]
          deleteat!(list, k)
        else 
          k+=1
        end
      end
      i+=1
    end
    append!(list, minimal_submodules(M,M.dim-index, lf))
  else 
  #
  #  Duality
  # 
    M_dual=dual_space(M)
    dlist=submodules(M_dual, M.dim-index)
    list=fq_nmod_mat[transpose(nullspace(x)[2]) for x in dlist]
  end 
  for x in list
    rref!(x)
    @hassert :MeatAxe 1 closure(deepcopy(x), M.G)==x
  end
  return list
    
end
