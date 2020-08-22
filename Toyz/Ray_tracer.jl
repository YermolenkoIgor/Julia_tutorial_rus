module RTr # ray tracer

    using Images
    using LinearAlgebra: dot, normalize, norm
    import Base: *
    *(a::Array{Float64,1}, b::Array{Float64,1}) = dot(a,b);

    mutable struct Light
        position::Vector{Float64}
        intensity::Float64
        Light(p, i) = new(p, i)
    end

    mutable struct Material
        diffuse_color::Vector{Float64}
        albedo::Vector{Float64}
        specular_exponent::Float64
        refractive_index::Float64
        Material(dc) = new(dc, [1.0, 0.0, 0.0, 0.0], 0.0, 0.0)
        Material(dc, al, se, ri) = new(dc, al, se, ri)
    end

    mutable struct Sphere
        center::Vector{Float64}
        radius::Float64
        material::Material
        Sphere(c, r, m) = new(c, r, m)
    end

    function ray_intersect(sph::Sphere, orig::Vector{Float64}, dir::Vector{Float64}, t0::Float64)
    
        L = sph.center - orig
        tca = L * dir
        d2 = L * L - tca * tca
        
        if d2 > sph.radius^2
            return false, t0
        end
        
        thc = sqrt(sph.radius^2 - d2)
        t0 = tca - thc
        t1 = tca + thc
        if t0 < 0 t0 = t1 end
        if t0 < 0 return false, t0 end
        return true, t0
    end

    reflect(I::Vector{Float64}, N::Vector{Float64}) = I - 2N*(I * N)

    function refract(I::Vector{Float64}, N::Vector{Float64}, η_t::Float64, η_i=1.0) # Snell's law
        cosi = -max(-1.0, min(1.0, I * N))
        if cosi<0 return refract(I, -N, η_i, η_t) end 
        # if the ray comes from the inside the object, swap the air and the media
        η = η_i / η_t
        k = 1 - η^2 * (1 - cosi^2)
        return k<0 ? [1.0,0.0,0.0] : I*η + N*(η*cosi - sqrt(k)) 
        # k<0 = total reflection, no ray to refract. I refract it anyways, this has no physical meaning
    end

    function scene_intersect( orig::Vector{Float64}, dir::Vector{Float64}, spheres::Vector{Sphere},
                         hit::Vector{Float64}, N::Vector{Float64}, material::Material )
    
        spheres_dist = Inf
        
        for s in spheres
            ri, dist_i = ray_intersect(s, orig, dir, 0.0)
            if ri && dist_i < spheres_dist
                spheres_dist = dist_i
                hit = orig + dir*dist_i
                N = normalize( hit - s.center )
                material = s.material
            end
        end

        # plane
        checkerboard_dist = Inf

        if abs(dir[2]) > 1e-3
            d = -(orig[2]+4)/dir[2] # the checkerboard plane has equation y = -4
            pt = orig + dir*d
            if d>0 && abs(pt[1])<10 && pt[3]<-10 && pt[3]>-30 && d<spheres_dist
                checkerboard_dist = d
                hit = pt
                N = [0.,1.,0.]
                material.diffuse_color = ( round(Int, 0.5hit[1]+1000) + 
                        round(Int, 0.5hit[3]) ) & 1 > 0 ? [.3, .3, .3] : [.3, .2, .1]
            end
        end
        return min(spheres_dist, checkerboard_dist) < 1000, orig, dir, hit, N, material
        
    end

    scene_intersect(orig, dir, spheres) = 
                scene_intersect(orig, dir, spheres, zeros(3), zeros(3), Material(zeros(3)))

function cast_ray(orig::Vector{Float64}, dir::Vector{Float64}, 
            spheres::Vector{Sphere}, lights::Vector{Light}, depth = 0.0)

        si, orig, dir, point, N, material = scene_intersect(orig, dir, spheres)
        if depth>4 || !si
            return [0.2, 0.7, 0.8] # background color
        end

        reflect_dir = normalize( reflect(dir, N) )
        refract_dir = normalize( refract(dir, N, material.refractive_index) )
        # offset the original point to avoid occlusion by the object itself:
        reflect_orig = reflect_dir * N < 0 ? point - N*1e-3 : point + N*1e-3     
        refract_orig = reflect_dir * N < 0 ? point - N*1e-3 : point + N*1e-3
        reflect_color = cast_ray(reflect_orig, reflect_dir, spheres, lights, depth + 1)
        refract_color = cast_ray(reflect_orig, reflect_dir, spheres, lights, depth + 1)
        
        diffuse_light_intensity = 0
        specular_light_intensity = 0

        for light in lights
            light_dir = normalize( light.position - point )
            light_distance = norm( light.position - point )
            shadow_orig = light_dir * N < 0 ? point - N*1e-3 : point + N*1e-3 
            # checking if the point lies in the shadow of the lights[i]

            si, shadow_orig, light_dir, shadow_pt, shadow_N, tmpmaterial = scene_intersect(shadow_orig, light_dir, spheres)
            if si && norm(shadow_pt-shadow_orig) < light_distance continue end

            diffuse_light_intensity  += light.intensity * max(0., light_dir * N)
            specular_light_intensity += max(0., (-reflect(-light_dir, N) * dir) ) ^ material.specular_exponent * light.intensity
        end
        
        return material.diffuse_color * diffuse_light_intensity * material.albedo[1] + 
                ones(3)*specular_light_intensity * material.albedo[2] + 
                reflect_color*material.albedo[3] + 
                refract_color*material.albedo[4]

    end

    function render(spheres::Vector{Sphere}, lights::Vector{Light}, 
                    width = 400, height = 400, fov = 0.33π)
    
        framebuffer = ones(3, width, height)

        for i = 1:height, j = 1:width
            x =  (i + 0.5) -  0.5width
            y = -(j + 0.5) + 0.5height  # this flips the image at the same time
            z = -height/(2tan(0.5fov))
            dir = normalize( [x, y, z] )
            framebuffer[:,j,i] = cast_ray( zeros(3), dir, spheres, lights )
        end
        
        colorview(RGB, framebuffer)
    end
end