module Bam
    
    using Images
    using LinearAlgebra: dot, normalize, norm, cross
    import Base: *
    *(a::Array{Float64,1}, b::Array{Float64,1}) = dot(a,b);

    function anim(;iTime = 1.0,
        MaxSteps = 64,
        StepDistanceScale = 0.5,
        MinStep = 0.001,
        DistThreshold = 0.005,
        VolumeSteps = 32,
        StepSize = 0.02,
        Density = 0.1,
        SphereRadius = 0.5,
        NoiseFreq = 4.0,
        NoiseAmp = -0.5,
        NoiseAnim = [0, -1, 0],
        width = 360,
        height = 360)

        m = [0.00,  0.80,  0.60,
            -0.80,  0.36, -0.48,
            -0.60, -0.48,  0.64]

        fract(x::Float64) = x - floor(x)
        hash(n::Float64) = fract(sin(n)*43758.5453)
        lerp(v0::Float64, v1::Float64, t::Float64) = v0 + (v1-v0)*max(0., min(1., t)) # linear interpolation
        lerp(v0::Vector{Float64}, v1::Vector{Float64}, t::Float64) = v0 + (v1-v0)*max(0., min(1., t)) # linear interpolation
        clamp(x::Float64, a::Float64, b::Float64) = min(max(x, a), b)

        function noise(x::Vector{Float64})
            p = floor.(x)
            f = fract.(x)

            f = f*(f*(3ones(3) - 2f))
            n = p*[1., 57., 113.]
            return lerp(lerp(
                             lerp(hash(n +  0.), hash(n +  1.), f[1]),
                             lerp(hash(n + 57.), hash(n + 58.), f[1]), f[2]),
                        lerp(
                            lerp(hash(n + 113.), hash(n + 114.), f[1]),
                            lerp(hash(n + 170.), hash(n + 171.), f[1]), f[2]), f[3])
        end

        function fbm(p::Vector{Float64})
            f  = 0.5000*noise(p); p = p*2.02
            f += 0.2500*noise(p); p = p*2.03
            f += 0.1250*noise(p); p = p*2.01
            f += 0.0625*noise(p)
            return f/0.9375
        end

        function distanceFunc(p::Vector{Float64}, displace::Float64)
            
            d = hypot(p...) - (sin(iTime*0.25)+0.5) # animated radius
            displace = fbm(p*NoiseFreq + NoiseAnim*iTime) # offset distance with pyroclastic noise
            d += displace * NoiseAmp;
            
            return d, displace
        end

        function dfNormal(pos::Vector{Float64}) 
            ε = 0.001
            d = distanceFunc(pos, 0.)[1]
            nx = distanceFunc(pos + [ε, 0, 0], 0.)[1] - d
            ny = distanceFunc(pos + [0, ε, 0], 0.)[1] - d
            nz = distanceFunc(pos + [0, 0, ε], 0.)[1] - d
            return normalize([nx, ny, nz])
        end

        function gradient(d::Float64)
            yellow = [4., 4., 4., 1.] # note that the color is "hot", i.e. has components >1
            orange = [1., 1., 0., 1.]
            red    = [1., 0., 0., 1.]
            gray = [0.4, 0.4, 0.4, 4.]
            darkgray = [0.2, 0.2, 0.2, 4.0]

            x = fract(d)
            if d < 0.3333
                return lerp(yellow, orange, x)
            elseif x < 0.6666
                return lerp(orange, red, x)
            elseif x < 0.75
                return lerp(red, gray, x)
            end
            
            return lerp(gray, darkgray, x)
        end

        # shade a point based on position and displacement from surface
        function shade(p::Vector{Float64}, displace::Float64)
            # lookup in color gradient
            displace = 1.5displace - 0.2
            displace = clamp(displace, 0.0, 0.99)
            c = gradient(displace)
            # lighting
            n = dfNormal(p);
            diffuse = 0.5n[3]+0.5
            c[1:3] = lerp( c[1:3], c[1:3]*diffuse, clamp( 2displace-1, 0.0, 1.0) )
            
            return c
        end

        function volumeFunc(p::Vector{Float64})
            displace = distanceFunc(p, 0.0)[2]
            c = shade(p, displace)
            return c
        end
        # sphere trace
        # returns hit position
        function sphereTrace(rayOrigin::Vector{Float64}, rayDir::Vector{Float64}, 
                                hit::Bool, displace::Float64)
            pos = rayOrigin
            hit = false
            displace, d, disp = 0., 0., 0. 
            
            for i in 1:MaxSteps
                d, disp = distanceFunc(pos, disp)
                    if d < DistThreshold
                        hit = true
                        displace = disp
                    end
                pos += rayDir*d*StepDistanceScale
            end
            
            return pos, hit, displace
        end

        function rayMarch(rayOrigin::Vector{Float64}, rayStep::Vector{Float64}, pos::Vector{Float64})
            
            summ = zeros(4)
            pos .= rayOrigin
            
            for i in 1:VolumeSteps
                col = volumeFunc(pos)
                col[4] *= Density
                col[4] = min(col[4], 1.0)
                # pre-multiply alpha
                col[1:3] *= col[4]
                summ = summ + col*(1.0 - summ[4])
                # exit early if opaque
                if summ[4] > OpacityThreshold
                    break
                end
                pos += rayStep
            end
            return summ
        end

        function mainImage(fragCoord::Vector{Float64}, w::Int64, h::Int64 )

        	iResolution = [w, h]
        	iMouse = [1., 1.]
            q = fragCoord ./ iResolution
            p = 2q .- 1.
            p[1] *= iResolution[1] / iResolution[2]
            
            rotx = (iMouse[2] / iResolution[2])*4.0;
            roty = 0.2iTime - (iMouse[1] / iResolution[1])*4.0
            
            # camera
            ro = 2.0*normalize( [cos(roty), cos(rotx), sin(roty)] )
            ww = normalize( [0.,0.,0.] - ro)
            uu = normalize( cross( [0.,1.,0.], ww ) )
            vv = normalize( cross(ww,uu) )
            rd = normalize( p[1]*uu + p[2]*vv + 1.5*ww );
            # sphere trace distance field
            hit = false
            displace = 0.0
            hitPos, hit, displace = sphereTrace(ro, rd, hit, displace)

            col = [0., 0., 0., 1.]
            if hit
                # shade
                col = shade(hitPos, displace)  # opaque version
                # col = rayMarch(hitPos, rd*_StepSize, hitPos); // volume render
            end

            fragColor = col
        end

        function idraw(str)

            framebuffer = zeros(4, height, width)

            for j = 1:height, i = 1:width
                
                framebuffer[:,j,i] = mainImage( [1.0j, 1.0i], width, height )
            end
            
            img = colorview(RGBA, framebuffer)
            save(str, img)
            img
        end

        idraw("$iTime.png")
    end
end