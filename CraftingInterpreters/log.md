# Log
## First steps
- Realizing Haskell has Lazy IO, which is not the best, if you want to create a strict imperative OOPL (tried System.IO.Strict, and Control.Deepseq)
  - Solution: flush input by hand, so that it won't hold on to it. (Lazy IO buffers all values, till it is absolutely needed)
  - Lists and String (which are character lists) are one-way linked lists which could have serious performance issues, changing to Sequence and Text
    - Talk about Sequences and finger trees
    - Why not Vectors (mutability)
    - Why did I use strict instead of lazy -> again performace issues (list concatenation, backwards traversal, indexing... etc)
    - Data.Set
- Parser Types and Recursive Descent Parser
- Error Handling
- States (variables,scopes...) in a stateless side-effectless programming languages (will see how it turns out)
  - State monad hashtable, for environments.
  - Talk about monads (and functors, applicatives)
  - I think we should talk about how the Environments work (sequence, and the last element is the innermost scope that we are in)
  - Closure implementation
- One gripe with Haskell: An even more fine-tuned type handling would be better, maybe I am not using the language the right way -> this is fixed with introducing happy and using better types
- I had a problem with parameterized types, and I could not create a good solution for a polymorphic type for functions (as I had to add everywhere that polymorphic type as type parameter) -> created a type for every native function

- Happy: much better than the Recursive descent algorythm I used before, less ambiguity in types as it forces a different thinking
- Show how happy works!
### Interesting problems 
#### The clock implementation
  - so the problem was that it saves the value only when it is used but because it is a zero param function -> it is a value, so when used it wil save the value and return anytime it is called again.
  - solution: make it a function that waits for an (Integer -> Integer) function, so when called it is a function
and will return a new value if you call it. But you have to call it with an (Integer -> Integer) function such as "id"

- Interesting stuff to talk about:
  - how conditionals, functions, blocks, environments are implemented
  - Closure is a environment inside an environment
  - Why Arity check is in Eval (we only check ids in resolver, not the actual value, that only happens in Eval)
  
- The structure seems weird. Haskell projects to look at for ideas:
  - Aura
  - xmobar
  - xmonad
  - Elm
