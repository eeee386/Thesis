# Log
## First steps
- Realizing Haskell has Lazy IO, which is not the best, if you want to create a strict imperative OOPL (tried System.IO.Strict, and Control.Deepseq)
  - Solution: flush input by hand, so that it won't hold on to it. (Lazy IO buffers all values, till it is absolutely needed)
  - Lists and String (which are character lists) are one-way linked lists which could have serious performance issues, changing to Sequence and Text
    - Talk about Sequences and finger trees
    - Why not Vectors (mutability)
    - Why did I use strict instead of lazy -> again perfonrmace issues (list concatenation, backwards traversal, indexing... etc)
- Parser Types and Recursive Descent Parser
- Error Handling
- States (variables,scopes...) in a stateless side-effectless programming languages (will see how it turns out)
  - State monad hashtable, for environments.
  - Talk about monads (and functors, applicatives)
  - I think we should talk about how the Environments work (sequence, and the last element is the innermost scope that we are in)
