using PyPlot, Statistics
# (c) Ludovic Raess (ludovic.rass@gmail.com)
@views function viscous_glacier2D()
	# physics - scales
	α       = 10.0                 # slope angle, degrees
	lx, ly  = 300.0, 100.0         # domain length X, Y, m
	ρg      = 900*9.8              # gravity acceleration, m/s^2
	μ       = 1e12                 # viscosity, Pa.s
	# numerics
	nx, ny  = 61, 21               # grid points X, Y
	niτ     = 14000                # number of iters
	# preprocessing
	dx, dy  = lx/(nx-1), ly/(ny-1) # grid spacing X, Y
	dτv     = min(dx,dy)^2/μ/4.1/2 # timestep
	dτp     = 4.1*μ/max(nx,ny)
	(xc, yc ) = (LinRange(-lx/2, lx/2, nx), LinRange(-ly/2, ly/2, ny))
	(Xc2,Yc2) = ([x for x=xc,y=yc], [y for x=xc,y=yc])
	(X2r,Y2r) = (Xc2*cosd(α) - sind(α)*Yc2, Xc2*sind(α) + cosd(α)*Yc2)
	# initial conditions
	Pt      = zeros(Float64, nx  ,ny  )
	∇V      = zeros(Float64, nx  ,ny  )
	Vx      = zeros(Float64, nx+1,ny  )
	Vy      = zeros(Float64, nx  ,ny+1) 
	dVxdτ   = zeros(Float64, nx-1,ny-2)
	dVydτ   = zeros(Float64, nx-2,ny-1)
	σ_xx    = zeros(Float64, nx  ,ny  )
	σ_yy    = zeros(Float64, nx  ,ny  )
	τ_xy    = zeros(Float64, nx-1,ny-1) 
	# action - iteration loop
	for iτ = 1:niτ
		# pressure and stress
		∇V    .= diff(Vx,dims=1)./dx .+ diff(Vy,dims=2)./dy      
		Pt    .= Pt .- ∇V.*dτp 
		σ_xx  .= 2.0*μ.*(diff(Vx,dims=1)./dx .- 1/3*∇V) .- Pt
		σ_yy  .= 2.0*μ.*(diff(Vy,dims=2)./dy .- 1/3*∇V) .- Pt
		τ_xy  .= μ.*(diff(Vx[2:end-1,:],dims=2)./dy .+ diff(Vy[:,2:end-1],dims=1)./dx)
		# free surface top boundary
		Pt[:,end]   .= 0
		σ_xx[:,end] .= 0
		τ_xy[:,end] .= 1/3*τ_xy[:,end-1] 
		# flow velocities Vx and Vy
		dVxdτ .= diff(σ_xx[:,2:end-1],dims=1)./dx .+ diff(τ_xy,dims=2)./dy .- sind(α).*ρg
		dVydτ .= diff(σ_yy[2:end-1,:],dims=2)./dy .+ diff(τ_xy,dims=1)./dx .- cosd(α).*ρg
		Vx[2:end-1,2:end-1] .= Vx[2:end-1,2:end-1] .+ dVxdτ.*dτv
		Vy[2:end-1,2:end-1] .= Vy[2:end-1,2:end-1] .+ dVydτ.*dτv
		# no sliding bottom boundary
		Vy[:,1] .= -Vy[:,2]
		# visualisation
		if mod(iτ,1000)==0 err = maximum([mean(abs.(∇V[:,1:end-1])), mean(abs.(dVxdτ)), mean(abs.(dVydτ))]); println("error = $err") end
	end
	# visu
	figure("pyplot_figure",figsize=(5.7,5.5)), clf()
	st = 4; s2d = 60*60*24
	(Xp,  Yp ) = (X2r[1:st:end,1:st:end], Y2r[1:st:end,1:st:end])
	(Vxp, Vyp) = (0.5*(Vx[1:st:end-1,1:st:end  ]+Vx[2:st:end,1:st:end]), 0.5*(Vy[1:st:end  ,1:st:end-1]+Vy[1:st:end,2:st:end]))
	subplot(311), pcolor(X2r,Y2r, 1e-3*Pt), plt.axis("off"), plt.title("pressure [kPa]"), plt.colorbar(fraction=0.02, pad=0.03)
	quiver(Xp, Yp, Vxp, Vyp, pivot="mid", color="white")
	subplot(312), pcolor(X2r,Y2r, s2d*Vx[2:end,:]), plt.axis("off"), plt.title("Vel-x [m/d]"), plt.colorbar(fraction=0.02, pad=0.03)
	subplot(313), pcolor(X2r,Y2r, s2d*Vy[:,2:end]), plt.axis("off"), plt.title("Vel-y [m/d]"), plt.colorbar(fraction=0.02, pad=0.03)
	return
end
viscous_glacier2D()
