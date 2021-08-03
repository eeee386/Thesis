# Log
## First steps
- Realizing Haskell has Lazy IO, which is not the best, if you want to create a strict imperative OOPL (tried System.IO.Strict, and Control.Deepseq)
  - Solution: flush input by hand, so that is won't hold on to it. (Lazy IO buffers all values, till it is absolutely needed)
