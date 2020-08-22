using LinearAlgebra: norm, nullspace

function initializeStarPosition(n, r, r_min, r_max)
# n: Number of stars per core.
# r: Core initial positions.
# rmin: core minimum radius.
# rmax: core maximum radius.
# s: randomly generated stars.
    N = size(r,1)
    s = zeros(N*n, 3)
    for core = 1:N
        rmin = r_min[core]
        rmax = r_max[core]
        rdiff = rmax - rmin;
        for i = 1:n
            r_rand = rand() * rdiff + rmin;
            θ = 2π*rand()
            num = n*(core-1) + i
            s[num,:] .= [ r_rand*cos(θ) + r[core,1]; r_rand*sin(θ) + r[core,2]; 0]
        end
    end
    return s
end


function initializeStarAcceleration(n, r, m, s_r)
# n: Number of stars per core.
# r: Core initial positions.
# m: Core masses.
# s_r: Star initial positions
# a: star initial accelerations.
    N = size(r,1)
    a = zeros(N*n, 3)
    for core = 1:N
        corepos = r[core,:]
        for i = 1:n
            num = n*(core-1) + i
            starpos = s_r[num,:]
            posdiff = corepos - starpos;
            acceleration = m[core] / norm(posdiff)^2
            unit_vector = posdiff / norm(posdiff)
            a[num,:] = acceleration * unit_vector
        end
    end
    return a
end

function coreAcceleration(m, r)
# m: Vector of length N containing the particle masses
# r: N x 3 array containing the particle positions
# a: N x 3 array containing the computed particle accelerations
    N = size(r,1)
    a = zeros(N, 3)
    for i = 1:N
        for j = 1:N
            if (i != j)
                m_j = m[j]
                r_i = r[i,:]
                r_j = r[j,:]
                r_ij = r_j - r_i
                x_ij = norm(r_ij)
                a[i,:] = a[i,:] + r_ij * (m_j / x_ij^3)
            end
        end
    end
    return a
end

function starAcceleration(s_r, r, N, n, m)
# s_r: N*n x 3 array containing the star positions
# r: N x 3 array containing the core positions
# N: Number of cores.
# n: Number of stars.
# m: core masses.
    a = zeros(N*n, 3)
    for i = 1:n*N
        for core = 1:N
            corepos = r[core,:]
            starpos = s_r[i,:]
            posdiff = corepos - starpos
            acceleration = m[core] / norm(posdiff)^2
            unit_vector = posdiff / norm(posdiff)
            a[i,:] = a[i,:] + acceleration * unit_vector
        end
    end
    return a
end

function initializeStarVelocity(n, r, v, s_r, s_a, cw)
# n: Number of stars per core.
# r: Core initial positions.
# v: Core initial velocities.
# s_r: Star initial positions.
# s_a: star initial accelerations.
# cw: determine star orbit direction
    N = size(r,1)
    s = zeros(N*n, 3)
    for core = 1:N
        corePos = r[core,:]
        xcore = corePos[1]
        ycore = corePos[2]
        vcore = v[core,:]
        clockwise = cw[core]
        for i = 1:n
            num = n*(core-1) + i
            starPos = s_r[num,:]
            xpos = starPos[1]
            ypos = starPos[2]
            xdiff = xcore - xpos
            ydiff = ycore - ypos
            if (xdiff < 0)
                direction = -permutedims(nullspace([xdiff ydiff]))
            else
                direction = permutedims(nullspace([xdiff ydiff]))
            end
            if (!clockwise)
                direction = -direction
            end
            acceleration = norm(s_a[num,:])
            distance = norm(corePos - starPos)
            speed = sqrt(acceleration * distance);
            velocity = direction / norm(direction) * speed
            s[num,:] = [velocity[1], velocity[2], 0] + vcore
        end
    end
    return s
end

function  particleSystem(tmax, level, coreNum, starNum, r0, v0, m, rmin, rmax, clockwise)
#  
#  Input arguments
#
#      tmax:       (real scalar) Final solution time.
#      level:      (integer scalar) Discretization level.
#      coreNum:    (integer scalar) Number of cores, use as N.
#      starNum:    (integer scalar) Number of stars, use as n.
#      r0:         (N x 3 array) Initial positions.
#      v0:         (N x 3 array) Initial velocity.
#      m:          (Vector of length N) particle masses
#      rmin:       (integar scalar) the minimum radius of the star distribution
#      rmax:       (integar scalar) the minimum radius of the star distribution
#      clockwise:  (boolean) true then stars move in clockwise
#
#  Output arguments
#
#      t:      (real vector) Vector of length nt = 2^level + 1 containing
#              discrete times (time mesh).
#      r:      (N x 3 array) Vector of length nt containing computed 
#              3D position of cores at discrete times t(n).
#      v:      (N x 3 array) Vector of length nt containing computed
#              3D velocity of cores at discrete times t(n).
#      s_r:    (N*n x 3 array) Vector of length nt containing computed
#              3D position of stars at discrete times t(n).
#      s_v:    (N*n x 3 array) Vector of length nt containing computed
#              3D velocity of stars at discrete times t(n).
#      s_a:    (N*n x 3 array) Vector of length nt containing computed
#              3D acceleration of stars at discrete times t(n).
###########################################################################
   # Tracing control: if 7th arg is supplied base tracing on that input,
   # otherwise use local defaults.
   
   # Define number of time steps and create t, position r and velocity v
   # arrays of appropriate size for efficiency (rather than "growing" 
   # them element by element)
   nt = 2^level + 1
   t = range(0.0, stop = tmax, length = nt);
   r = zeros(coreNum, 3, nt)
   v = zeros(coreNum, 3, nt)
   s_r = zeros(coreNum*starNum, 3, nt)
   s_v = zeros(coreNum*starNum, 3, nt)
   s_a = zeros(coreNum*starNum, 3, nt)
   
   # Determine discrete time step from t array.
   deltat = t[2] - t[1]

   # Initialize first two values of the particle"s displacement.
   r[:,:,1] = r0;
   r[:,:,2] = r0 + deltat * v0 + 0.5 * deltat^2 * coreAcceleration(m, r0)
   
   # Initialize stars inital position
   s_r[:,:,1] = initializeStarPosition(starNum, r0, rmin, rmax)
   
   # Initialize stars initial acceleration
   s_a[:,:,1] = initializeStarAcceleration(starNum, r0, m, s_r[:,:,1])
   
   # Initialize stars initial velocity
   s_v[:,:,1] = initializeStarVelocity(starNum, r0, v0, s_r[:,:,1], s_a[:,:,1], clockwise)
   
   # Initialize first value of the velocity.
   v[:,:,1] = v0

   # Evolve the system to the final time using the discrete equations
   # of motion.  Also compute an estimate of the velocity at 
   # each time step.
   tracefreq = 100

   for n = 2 : nt - 1
      # This generates tracing output every "tracefreq" steps.
      
      if rem(n, tracefreq) == 0
         println("system: Step $n of $nt")
      end

      r[:,:,n+1] = 2 * r[:,:,n] - r[:,:,n-1] + deltat^2 * coreAcceleration(m, r[:,:,n])
      
      s_a[:,:,n] = starAcceleration(s_r[:,:,n-1], r[:,:,n-1], coreNum, starNum, m);
      s_v[:,:,n] = s_v[:,:,n-1] + s_a[:,:,n] * deltat;
      s_r[:,:,n] = s_r[:,:,n-1] + s_v[:,:,n] * deltat;

      v[:,:,n] = (r[:,:,n+1] - r[:,:,n-1]) / (2deltat);
   end
   # Use linear extrapolation to determine the value of omega at the 
   # final time step.
   v[:,:,nt] = 2 * v[:,:,nt-1] - v[:,:,nt-2]

   #return [t, r, v, s_r, s_v, s_a]
   return t, r, s_r
end


#-----------------------------------------------------------
# Set up initial condition (case 2 cores rotate in z-plane)
#-----------------------------------------------------------
# N = 2;
# n = 1;
# r0 = [-1 0 0; 1 0 0];
# v0 = [0.2575 0.2543 0; 0.8407 0.8143 0];
# m = [1; 1];
# rmin = [200; 200];
# rmax = [500; 500];
# clockwise = [false; false];
#-----------------------------------------------------------
# Set up initial condition (case 1 core)
#-----------------------------------------------------------
# N = 1;
# n = 2500;
# r0 = [0 0 0];
# v0 = [0 0 0];
# m = 4*10^6;
# rmin = 400;
# rmax = 1500;
# clockwise = true;
