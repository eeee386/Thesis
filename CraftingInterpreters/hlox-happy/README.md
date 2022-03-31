# hlox-happy

Rewrite of the hlox but using happy parser

## Basics

### Setup haskell (Ubuntu 20.04 LTS)
- install GHCup
- if it fails run: `sudo apt update -y && sudo apt install build-essential curl libffi-dev libffi7 libgmp-dev libgmp10 libncurses-dev libncurses5 libtinfo5 -y`
- Fix paths (`export PATH="$PATH:$HOME/.cabal/bin:$HOME/.ghcup/bin:$PATH"`)
- `stack install happy` (and fix paths)
- Fix path`export PATH="$PATH:$HOME/.local/bin/happy"`

### Start project
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