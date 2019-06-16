struct DerivativeOperator{T<:Real,S1<:SVector,S2<:SVector} <: AbstractDerivativeOperator{T}
    derivative_order        :: Int
    approximation_order     :: Int
    dx                      :: T
    dimension               :: Int
    stencil_length          :: Int
    stencil_coefs           :: S1
    boundary_stencil_length :: Int
    boundary_point_count    :: Int
    low_boundary_coefs      :: Vector{S2}
    high_boundary_coefs     :: Vector{S2}

    function DerivativeOperator{T,S1,S2}(derivative_order::Int,
                                     approximation_order::Int, dx::T,
                                     dimension::Int) where
                                     {T<:Real,S1<:SVector,S2<:SVector}
        dimension               = dimension
        dx                      = dx
        stencil_length          = derivative_order + approximation_order - 1 + (derivative_order+approximation_order)%2
        boundary_stencil_length = derivative_order + approximation_order
        dummy_x                 = -div(stencil_length,2) : div(stencil_length,2)
        boundary_x              = -boundary_stencil_length+1:0
        boundary_point_count    = div(stencil_length,2) - 1 # -1 due to the ghost point
        # Because it's a N x (N+2) operator, the last stencil on the sides are the [b,0,x,x,x,x] stencils, not the [0,x,x,x,x,x] stencils, since we're never solving for the derivative at the boundary point.
        deriv_spots             = (-div(stencil_length,2)+1) : -1
        boundary_deriv_spots    = boundary_x[2:div(stencil_length,2)]

        stencil_coefs           = convert(SVector{stencil_length, T}, calculate_weights(derivative_order, zero(T), dummy_x))
        low_boundary_coefs      = [convert(SVector{boundary_stencil_length, T}, calculate_weights(derivative_order, oneunit(T)*x0, boundary_x)) for x0 in boundary_deriv_spots]
        high_boundary_coefs     = reverse!(copy([convert(SVector{boundary_stencil_length, T}, reverse(low_boundary_coefs[i])) for i in 1:boundary_point_count]))

        new(derivative_order, approximation_order, dx, dimension, stencil_length,
            stencil_coefs,
            boundary_stencil_length,
            boundary_point_count,
            low_boundary_coefs,
            high_boundary_coefs
            )
    end
    DerivativeOperator{T}(dorder::Int,aorder::Int,dx::T,dim::Int) where {T<:Real} =
        DerivativeOperator{T, SVector{dorder+aorder-1+(dorder+aorder)%2,T}, SVector{dorder+aorder,T}}(dorder, aorder, dx, dim)
end

#=
    This function is used to update the boundary conditions especially if they evolve with
    time.
=#
function DiffEqBase.update_coefficients!(A::DerivativeOperator{T,S}) where {T<:Real,S<:SVector}
    nothing
end

#################################################################################################

(L::DerivativeOperator)(u,p,t) = L*u
(L::DerivativeOperator)(du,u,p,t) = mul!(du,L,u)
