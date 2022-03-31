# Programozási nyelv írása Haskellben

## Bevezetés

### Robert Nystrom: Crafting Interpreters

### Haskell

#### Funkcionális programozás alapjai

- Listák
- Pattern matching
- Monoid, Semigroup
- Functor, Applicative, Monad
- Sequence
- Vector: a kakukktojás

#### Haskell típusosság

#### Felbukkanó problémák

- Imperatív vs Funkcionális
  - Side-effektek hiánya és hatásai (State kezelés)
  - Lazy IO (Runner.hs and clock)

### Projekt

#### Stack és Cabal

- Mit csinál a Cabal
- Mit csinál a Stack

#### Használt Cabal package-ek

## Lox

### Lox bemutatása

- Szintax
- Viselkedés
- Error kezelés

### jLox és hLox különbségei

- Aritás ellenőrzés
- Init
- Error kezelés

## Scanner/Lexer

### Mi az a Scanner/Lexer?

### Különbség az első és a mostani megoldás között

## Parser

### Mi az a Parser?

### LR és Generic Recursive Descent bemutatása

### Happy és az első megoldás

#### Happy bemutatása

- Szintax
- Predencia és asszocivitás állítás
- Info fájl bemutatása

#### Első megoldás bemutatása

#### Kettő összehasonlítása

- Főleg, hogy milyen szépen dokumentálja magát

## Resolver

### Mi az a Resolver?

- Feladatok

### Első és a mostani megoldás bemutatása

## Eval

### Mit csinál az Eval?

- Általános logikák leírása
  - Return
  - RuntimeError
  - Break, Continue
  - "Mindig csak az utolsó eval érdekel minket"

### Első és a mostani megoldás bemutatása

## Példák

### While és For loop

- Rezolválás Looppá
- Indexed és Closure változók

```Lox
var a = clock(); 
for (var i = 0; i < 1000000; i = i+1) {
 i;
} 
var b = clock(); 
print b-a;
```

```Lox
fun count(n) {
  while (n < 5) {
    if (n == 3) {
      print n;
    } 
    n = n + 1;
  }
} 
print count(1);
```

### Rekurzív Fibonacci

- Closure kezelés, self-recursion
- if kezelés

```Lox
fun fib(n) {
  if (n <= 1) {
    return n;
  } 
  return fib(n-2) + fib(n-1);
} 
for (var i = 0; i < 20; i = i + 1) {
  print fib(i);
}
```

### Háromszintes öröklődés

- Superclass-ok kezelése
- Superclass metódus hívása

```Lox
class A{
  init(){
    print "A";
  }
  cook(){
    print "cook";
  }
}

class B < A{
  init(){
    print "B";
    super.init();
  }
}

class C < B{
  init(){
    print "C";
    super.init();
  }
}

var d = C();
d.cook();
```

### Closure példa

```Lox
fun makeCounter() {
  var i = 0; 
  fun count() {
    i = i + 1;
    print i;
  }
  return count;
}
var counter = makeCounter(); 
counter(); 
counter();
```

## Javítani valók

### Errorkezelés

- Használni a happy **Monadic Parsers** részét
  - Beletenni sor és token információt az AST-be -> jobb resolver és runtime error

### Edgecase-ek javítása

- Még mindig vannak benne hibák -> Nem volt időm levelezősként javítani

### Array

- Dinamikus tömbök készítése
- Lehetséges megoldás: Natív osztály

### IO

### Modulok









