# hlox-happy

Rewrite of the hlox but using happy parser

## Basics

### Start project
- `stack install happy` (and fix paths)
- `stack build happy` 
  - (only first time, use bash, I did not test it on windows)
  - If it does not work install happy globally and try it that way
- `stack build`

### Run Interpreter
- `stack build --exec hlox-happy-exe`

### Run files
- `stack ghci`
  - then in the ghci run: `:main <path-to-file>`
  - src/test2.lox can be used as an example

### Generate HappyParser file
- `happy src/HappyParser.y -i -o src/Generated/HappyParser.hs`