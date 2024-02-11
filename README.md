# Prey(fishes)-Predator(sharks) System
This agent-based model simulates a dynamic predator-prey ecosystem within a virtual ocean environment, focusing on the interactions between sharks (predators) and fish (prey). The simulation aims to capture the essence of ecological balance, showcasing how energy exchange, reproduction, and survival strategies contribute to the stability or fluctuation of marine life populations.

## Environment
- Ocean: The black box is represented as an ocean.
- Algae Patches: At initialization and randomly throughout the simulation, food patches appear to represent the accumulation of algaes. These patches become consumable for the fishes.

## Behaviors
### General (prey and predator)

### Fish (Prey)
- Diet: Fish feed on consumable food patches (algae, worms, jellyfish, etc.).
- Energy: Fish have a variable maximum energy level, similar to sharks, settable before the simulation.
- Reproduction: Fish have the opportunity to reproduce when they meet another fish within a specific radius.
- Schooling Behavior: Fish can form schools, providing safety in numbers.
- Lifespan: Fish die when their energy level falls to zero.

### Shark (Predator)
- Diet: Sharks consume fish, gaining 1 energy unit per fish consumed.
- Energy: Sharks have a variable maximum energy level set before the simulation starts. 
- Reproduction: When two sharks encounter each other, there is a chance for reproduction.
- Lifespan: Sharks die when their energy depletes to zero.
  
### Algae (Food)
- Gets eaten by fishes

### Jellyfish (Food)
- Gets eaten by fishes

## Simulation Dynamics
- Food Dynamics: Food patches spawn randomly to simulate the natural growth cycles of algaes and jellyfisges.
- Energy and Movement: Both sharks and fish expend energy to move. This energy can be replenished by consuming food (fish or food patches).
- Interactions and Behaviors: The model captures various behaviors, including predation, reproduction, and schooling.
- Environmental Factors: The model allows for the exploration of how environmental changes, represented by the variability and distribution of food patches, impact the behaviors and survival of sharks and fish.
