# PSO

> Primary Goal: Develop a PSO code without the use of any AI assistance at all 

## Preparing requirements

### The equation

> This is the basic version of PSO, with variants changing how velocity updates and how bests are updated. Currently the goal is simple implementation with further improvements later down the road.

The ***Position update*** equation is given by: 

$$
P_i^{t+1}=P_i^t+V_i^{t+1}
$$

The ***Velocity update*** equation is give by:

$$
V_{ij}^{t+1}= wV_{ij}^t + c_1r_1(P_{best(i)j}^t - P_{ij}^t) + c_2r_2(P_{{Gbest}j}^t - P_{ij}^t)
$$

Where:

- $wV_{ij}^t$ : is the *inertial component* with $w$ as inertia

- $c_1r_1(P_{best(i)j}^t - P_{ij}^t)$ : is the *cognitive component* which shows the difference between the particle and its known personal best

- $c_2r_2(P_{{Gbest}j}^t - P_{ij}^t)$: is the *social component* which shows the difference between the particle and the currently known global best

- $r_1$ and $r_2$:  These are random numbers which act as perturbations for exploration

- $c_1$ and $c_2$: These are positive acceleration constants used to scale the contribution of the components

---

### What are the components of PSO?

We require the following for our class

- Number of particles in population 

- The fitness function (we assume that we wish to **maximize**)
  
  > if it is a minimization function, just multiply fitness function by -1

- The number of parameters in objective function 

- Constraints (if any)

- The constants as defined in the equation above

- Bounds for parameters

We also need to keep track of internal state hence we will have:

- Particle positions

- Particle Velocities

- Personal best position

- Global best position

### Considerations

#### Verifying argument count

I needed to extract the number of parameters from the objective function. For this purpose I found `__code__` object. This describes different aspects of a **function** based on its **byte code**. 

Since the objective and constraint functions will be **callable**, I can use this object to get the argument count to enforce this condition.

> This does not take into account args and kwargs so ensure that all the constrain and fitness functions have well defined arguments.

```python
def func(x,y,z):
    return x+y+z
func.__code__.co_argcount
```

#### Handling Bounds

Another thing to ensure is ***bounds***. These are required to generate initial positions of the swarm. These can also be considered as constraints that the position of the particle must not fall outside these bounds but that is an option Ill add later. For now Ill make the bounds only for initial position generation with the shape `(num_parameters,2)` 

I was unable to find any way to sample values uniformly in a range for each value in a numpy array of random values. So found a technique under `random_sample` which is as follows:

`(b-a)*random + a` can be used to generate a value uniformly in the range $[a,b]|b>a$

The only issue I can see is that the *range* will reduce the fineness (not sure if that's a correct usage) of the generated point. Numpy broadcasting made it easy to implement this.

#### Evaluating fitness

I also decided to enforce that fitness and constraint functions must take the same number of parameters. Since the parameters are separate and not just lists, I had to unpack them before evaluation using `*`. This may cost computational efficiency that numpy might use when directly applying a function row-wise. I will **revisit** this later.

> Another mistake I made here was not implementing the penalty as I had not decided it yet, refer to [this](#important-change)

#### Constraint handling techniques

Another choice I have to make is whether to make a flat penalty for failing constraint or have the constraint return a penalty score.    

- Penalty score would work great in case of linear constraint, but in cases where the constraints are more complex with complex feasible region, the deviation may get difficult to compute and may not give accurate direction towards optimal solution

- On other hand, a simple pass or fail condition would be able to handle all constraints, and simply penalize the particles for failing the condition based on penalty weights (to prioritize different constraints) or singular penalty. The problem with this approach is that it is impartial to the margin by which the constraint it failed. This may make the algorithm behavior more dependent on the hyperparameters. Regardless I will be using this method as it can be more widely used (in my opinion). 

I also found a paper by *(Innocente,2021)* discussing CHT, which did a thorough comparative study, though its conclusion was that it depended on a case by case basis.

### Code

```python
class ParticleSwarm:
    def __population_initializer(self)->np.ndarray:
        lower_bounds,upper_bounds=self.bounds.T
        difference=upper_bounds-lower_bounds
        population=(np.random.random(size=(self.num_particles,self.num_parameters))*difference)+lower_bounds
        return population.astype(np.float32)

    def __constraint_param_checker(self,constraints:list[Callable]):
        for constraint in constraints:
            if (constraint.__code__.co_argcount!=self.num_parameters):
                return False
        return True

    @staticmethod
    def __apply_function_rowwise(population:np.ndarray,func:Callable):
        return np.array([func(*particle) for particle in population],dtype=np.float32)

    def __init__(self,
                 num_particles:int,
                 fitness_function:Callable,
                 bounds:np.ndarray,
                 constraints:list[Callable]=None,
                 constraint_penalty:float | list | np.ndarray =1000.0,
                 c1:float=1.0,
                 c2:float=1.0,
                 inertia:float=0.5, 
                 ):
        self.num_particles=num_particles
        self.fitness_function=fitness_function
        self.num_parameters=fitness_function.__code__.co_argcount
        assert bounds.ndim>1 and bounds.shape==(self.num_parameters,2),f"The bounds must be of shape {(self.num_parameters,2)}."
        self.bounds=bounds
        self.population=self.__population_initializer()
        if constraints:
            assert self.__constraint_param_checker(constraints) , "Incorrect argument count for constraints"
            self.constraints=constraints
            if isinstance(constraint_penalty,(int,float)):
                self.constraint_penalty=np.array([constraint_penalty]*len(constraints))
            elif len(constraints)==len(constraint_penalty) and isinstance(constraint_penalty,(list,tuple,set,np.ndarray)):
                self.constraint_penalty=constraint_penalty
            else:
                raise AssertionError(f'Number of constraints and constraint penalties do not match {len(constraint_penalty)}!={len(constraints)}, or incorrect data type {type(constraint_penalty)}')                
        self.velocity=np.zeros_like(self.population,dtype=np.float32)
        self.c1=c1
        self.c2=c2
        self.inertial=inertia
        # local state 
        self.personal_best=self.population.copy()
        self.personal_best_fitness=ParticleSwarm.__apply_function_rowwise(self.population,self.fitness_function)
        _best_idx=np.argmax(self.personal_best_fitness)
        self.global_best_fitness=self.personal_best_fitness[_best_idx]
        self.global_best_particle=self.population[_best_idx]elf.global_best_particle=self.population[_best_idx]
```

## Computing Updates

The update loop will consist of these steps:

1. Compute the velocity update

2. Update the current position

3. Compute fitness of current position (and penalize for constraints if applicable)

4. Update the personal and global best 

I just implemented the formulas mentioned very early on. 

Also had to invert the penalty if it existed as the function returned true if it satisfied the constraint, which gets cast to `1.0` in the numpy array. 

### Code

```python
    def _update_velocity(self):
        shape=self.population.shape
        inertial_component=self.velocity*self.inertia
        cognitive_component=(self.c1*(self.personal_best-self.population))*np.random.rand(*shape)
        social_component=(self.c2*(self.global_best_particle-self.population))*np.random.rand(*shape)
        self.velocity=inertial_component+cognitive_component+social_component
        return

    def _update_fitness(self):
        # unconstrainted fitness score
        fitness=ParticleSwarm.__apply_function_rowwise(self.population,self.fitness_function)
        # penalizing for constraints
        if self.constraints:
            for constraint,penalty_multiplier in zip(self.constraints,self.constraint_penalty):
                failed=ParticleSwarm.__apply_function_rowwise(self.population,constraint)
                # since this returns a numpy array I need to turn 1s into 0s and vice versa
                failed=-(failed-1.0)
                fitness-=(failed*penalty_multiplier)
        self.fitness=fitness
        return

    def _update_best_particles(self):
        # updating personal bests
        for idx,(particle_fitness,personal_best_fitness) in enumerate(zip(self.fitness,self.personal_best_fitness)):
            if particle_fitness>personal_best_fitness:
                self.personal_best[idx]=self.population[idx]
                self.personal_best_fitness[idx]=self.fitness[idx]
        iter_best_idx=np.argmax(self.fitness)
        if self.fitness[iter_best_idx]>self.global_best_fitness:
            self.global_best_fitness=self.fitness[iter_best_idx]
            self.global_best_particle=self.population[iter_best_idx]
        return 

    def _update_position(self):
        self.population+=self.velocity
        return

    def update(self, verbose=False):
        self._update_velocity()
        self._update_position()
        self._update_fitness()
        self._update_best_particles()
        if verbose:
            average_fitness=np.average(self.fitness)
            print(f"Average Fitness: {average_fitness} \t Global Best: {self.global_best_fitness}")

    def run(self,iterations:int=50):
        for it in range(iterations):
            if it%10==0:
                self.update(verbose=True)
            else:
                self.update()
        return
```

### Important change

Since I have implemented a fitness update function , i will be using it to set the pbest and gbest fitness in `init` function as well. Especially since I forgot to add the penalty to it earlier. This will ensure proper operation of the code.

## Final remarks and base code

This winds up the basic core implementation.

What I plan to add are:

- A function which can generate an animation for 1-3D 

- Add parameters to allow for option toggles which allow for modification as to when the best pos are updated

- Add a function which converts strings to callable functions which can be fed to this code

### Final Base Code

```python
class ParticleSwarm:
    def __population_initializer(self)->np.ndarray:
        lower_bounds,upper_bounds=self.bounds.T
        difference=upper_bounds-lower_bounds
        population=(np.random.random(size=(self.num_particles,self.num_parameters))*difference)+lower_bounds
        return population.astype(np.float32)

    def __constraint_param_checker(self,constraints:list[Callable]):
        for constraint in constraints:
            if (constraint.__code__.co_argcount!=self.num_parameters):
                return False
        return True

    @staticmethod
    def __apply_function_rowwise(population:np.ndarray,func:Callable):
        return np.array([func(*particle) for particle in population],dtype=np.float32)

    def __init__(self,
                 num_particles:int,
                 fitness_function:Callable,
                 bounds:np.ndarray,
                 constraints:list[Callable]=None,
                 constraint_penalty:float | list | np.ndarray =1000.0,
                 c1:float=1.0,
                 c2:float=1.0,
                 inertia:float=0.5, 
                 ):
        self.num_particles=num_particles
        self.fitness_function=fitness_function
        self.num_parameters=fitness_function.__code__.co_argcount
        assert bounds.ndim>1 and bounds.shape==(self.num_parameters,2),f"The bounds must be of shape {(self.num_parameters,2)}."
        self.bounds=bounds
        self.population=self.__population_initializer()
        if constraints:
            assert self.__constraint_param_checker(constraints) , "Incorrect argument count for constraints"
            self.constraints=constraints
            if isinstance(constraint_penalty,(int,float)):
                self.constraint_penalty=np.array([constraint_penalty]*len(constraints))
            elif len(constraints)==len(constraint_penalty) and isinstance(constraint_penalty,(list,tuple,set,np.ndarray)):
                self.constraint_penalty=constraint_penalty
            else:
                raise AssertionError(f'Number of constraints and constraint penalties do not match {len(constraint_penalty)}!={len(constraints)}, or incorrect data type {type(constraint_penalty)}')                
        self.velocity=np.zeros_like(self.population,dtype=np.float32)
        self.c1=c1
        self.c2=c2
        self.inertia=inertia
        # local state 
        self.personal_best=self.population.copy()
        self._update_fitness()
        self.personal_best_fitness=self.fitness.copy()
        _best_idx=np.argmax(self.personal_best_fitness)
        self.global_best_fitness=self.personal_best_fitness[_best_idx]
        self.global_best_particle=self.population[_best_idx]

    def _update_velocity(self):
        shape=self.population.shape
        inertial_component=self.velocity*self.inertia
        cognitive_component=(self.c1*(self.personal_best-self.population))*np.random.rand(*shape)
        social_component=(self.c2*(self.global_best_particle-self.population))*np.random.rand(*shape)
        self.velocity=inertial_component+cognitive_component+social_component
        return

    def _update_fitness(self):
        # unconstrainted fitness score
        fitness=ParticleSwarm.__apply_function_rowwise(self.population,self.fitness_function)
        # penalizing for constraints
        if self.constraints:
            for constraint,penalty_multiplier in zip(self.constraints,self.constraint_penalty):
                failed=ParticleSwarm.__apply_function_rowwise(self.population,constraint)
                # since this returns a numpy array I need to turn 1s into 0s and vice versa
                failed=-(failed-1.0)
                fitness-=(failed*penalty_multiplier)
        self.fitness=fitness
        return

    def _update_best_particles(self):
        # updating personal bests
        for idx,(particle_fitness,personal_best_fitness) in enumerate(zip(self.fitness,self.personal_best_fitness)):
            if particle_fitness>personal_best_fitness:
                self.personal_best[idx]=self.population[idx]
                self.personal_best_fitness[idx]=self.fitness[idx]
        iter_best_idx=np.argmax(self.fitness)
        if self.fitness[iter_best_idx]>self.global_best_fitness:
            self.global_best_fitness=self.fitness[iter_best_idx]
            self.global_best_particle=self.population[iter_best_idx]
        return 

    def _update_position(self):
        self.population+=self.velocity
        return

    def update(self, verbose=False):
        self._update_velocity()
        self._update_position()
        self._update_fitness()
        self._update_best_particles()
        if verbose:
            average_fitness=np.average(self.fitness)
            print(f"Average Fitness: {average_fitness} \t Global Best: {self.global_best_fitness}")

    def run(self,iterations:int=50):
        for it in range(iterations):
            if it%10==0:
                self.update(verbose=True)
            else:
                self.update()
        return
```

---

# Repository related notes

The final version of code has animation functionality and neighborhood best PSO topology option. The details of that are not available here as that development was after the learning process and hence was not documented. 
