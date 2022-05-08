# Programozási nyelv írása Haskellben

## Bevezetés

### Előszó

Megszeretném köszönni Szabolcs Ivánnak minden segítséget amit nyújtott, ami sokat segített abban, hogy ez a szakdolgozat létrejöjjön.

### Rövid összefoglalás

A feladat, amit megakartam valósítani az egy imperatív, objektum orientált programozási nyelv megírása Haskell programozási nyelvben.
Ennek a programozási nyelvnek az alapja a Lox nevű programozási nyelv volt, amit tárgyalok a későbbiekben.
Elsődleges célom a feladattal a tanulás volt, hogy megértésem legyen a programozási nyelvekből. És ez szerintem teljesült. (!)

### Robert Nystrom: Crafting Interpreters

Első kiindulási alapom ez a könyv volt. Ebben a könyvben az író betekintést ad programozási nyelvek írásába egy tanuló programozási nyelven keresztül, amit Loxnak hív.
Ezen mutatja be az AST (Abstract Syntax Tree) interpretert, és a modernebb Virtual Machine alapú programozási nyelvek alapjait, és a programozási nyelv fejlesztők, nyelvi és szakami térházát.
Első részben a Robert Nystrom Javában írja meg az AST interpretert, amiben bemutatja egy nyelv legfőbb jellemzőit, és hogy működnek az alap egységei egy nyelvnek.
Második részben pedig C-ben megírja ugyanezt és itt már jobban fókuszál a Virtual Machine-ek működésére.

### Funkcionális programozás alapjai

#### Listák

A funckionális programozás alap adatstruktúrája. Egy egyszerű láncolt lista, a legtöbb helyen ezt a adattípust fogom használni a nyelv különböző fázisokban lévő elemeinek tárolására. A haskellben lusta kiértékelésű, ami azt jelenti, hogy nem előre lefoglalja a memóriát, hanem, akkor hozza létre a lista elemeit, amikor muszáj neki. 


```haskell
data [a] = [] | a : [a]
```

#### Pattern Matching

Az elágazás egy formája. (!)

```haskell
-- A "tail" függvény ha üres a lista, akkor visszaadja az üres listát, ha pedig nem üres akkor az első elemet leveszi a listáról és ezt az új listát adja vissza.
tail :: [a] -> [a]
tail [] = []
tail (x:xs) = xs
```

#### Monoid, semigroup (!)

#### Functor, Applicative, Monad (!)

#### Sequence

A haskellben a kétirányú lista, ami valójában egy fa.
Első és utolsó elem megtalálsa, levétele, módosítása konstans idejű, középső elem hasonló műveletei pedig log(n) idejűek
(! Szekvencia hozzáadása a programhoz)
(!implementáció kiírása innen: Ralf Hinze and Ross Paterson, ["Finger trees: a simple general-purpose data structure"](http://www.staff.city.ac.uk/~ross/papers/FingerTree.html), Journal of Functional Programming 16:2 (2006) pp 197-217.)

```haskell
import qualified Data.Sequence as S


```


#### Text, Vektor & Hashmap: a kakukktojások

Ez a három adatstruktúra az, ami nem funkcionális, de a amit adnak teljesítményben az jobb volt a teljesen funkcionális adatstruktúrákhoz képest
##### Text
- Tér és idő hatékony implemetálása a Stringnek, ami szembemegy a lusta kiértékelésű listával
- A memóriát előre lefoglalja (Strict)
- Elérés műveletek konstans idejűek szemben a listával
- Hozzáadás (előre, hátra, közbenső) O(n) -> Új Textet hoz létre
##### Vektor
- Az hasonlóan működik egy C++-os dinamikus tömbhöz
- Leginkább használt műveletek:
  - Elérés index alapján O(1)
  - Hozzáadás a végéhez O(1)
  - A index helyén érték változtatás O(1)
- A szekvenciában az index alapján való keresés és értékváltoztatás az log(n)-es így jobb teljesítményt értem el a Vektorral
##### Hashmap 
- Imperatív leképezés, ennél az adatstruktúránál kellett használni Monádokat
- Leginkább használtműveletek
  - Elérés kulcs alapján: O(1)
  - Kulcs-érték pár hozzáadás: O(1)
  - Érték változtatás: O(1)
- A Hasonló Data.Map adatstruktúra is egy adatstruktúrára épül, így nem lesz olyan hatékony az elérésben és az érték változtatásban

#### Felbukkanó problémák

##### Imperatív vs. Funkcionális (!)

Imperatív: egymást követő utasítások sorozatából áll
Funkcionális: rekurzív függvény hívások sorozata 

##### Pure programming vs. Side Effects

Haskellben nincsen állapot kezelés és meg kellett oldanom, hogy valahogyan az állapot az meglegyen a későbbiekre.
- Itt egy meta objektumot használtam, amit a függvényeknek átadtam és abból készítették el az új állapotot, amit használtam a további műveletekhez.
  - Erre majd a változó kezelésnél mutatok példát a későbbiekben
- Másik következmény, pedig az, hogy minden változtatásnál, új másolat jön létre az adott objektumból
  - Erre majd a closure implementációnál mutatok példát miért érdekes ez

##### Lazy IO vs. Strict IO

- A legtöbb nyelv szigorú (Strict) kiértékelésű, és minden szembejövő adatot azonnal kiértékel
- Míg Haskellben pedig lusta kiértékelés van, ami azt jelenti, hogy addig nem értékel ki adatokat, amíg nem muszáj
- Például:
  - Lista, míg egy szigorú kiértékelésű nyelvben lefoglalja előre a memóriát, és létrehozza a listát, ha le tud foglalni annyi memóriát. Ha nem sikerül,  akkor memória hibát dob, a haskellben a 
  ```haskell
  [1..]
  ```
  kiértékelődik, és addig növeli a listát, amíg a memória el nem fogy

- Az IO is lusta a Haskellben, tehát addig nem tesz semmit, amíg nem muszáj neki, és puffereli a bejövő értékeket
  - Ez problémás egy olyan esetben, amikor egy interaktív shellt is szeretnék létrehozni a nyelvhez
  - Ezt kézzel kell flusholni
  ```haskell
-- Meghívja a "readFromRepl" függvényt, ami kiírja, hogy Lox, flusholja a puffert, és elmenti a sort a pufferben volt
-- Ezt elmnetjük az outputba
-- Futtatjuk az inputot
-- Majd újra meghívjuk a "runPrompt" függvényt
runPrompt :: IO()
runPrompt = do
  input <- readFromRepl
  run (T.pack input)
  runPrompt

readFromRepl :: IO String
readFromRepl = putStr "Lox> "
     >> hFlush stdout
     >> getLine
  ```
  
- Clock (!Megnézni másik megoldást)

### Projekt

#### Cabal és Stack

##### Cabal
- Build és csomagoló rendszer
- Egy közös interfész a csomag készítőknek és elosztóknak, hogy könnyen tudják az alkalmazásaikat terjeszteni
- Cabal csak csomagok szintjén létezik

##### Stack
- Cabalra épülő build eszköz
- Fő feladata, hogy a Haskell projekteket kényelmesen lehessen kezelni
- Fontosabb funkciók:
  - Csomagok regisztrálása és telepítése
  - Függőség kezelés és feloldás
  - Ismételhető buildek - Ha ma futtatsz `stack build`-et és holnap is, akkor mindakét esetben ugyanazt kell kapnod (operációs rendszer különbségek és más beálítások miatt ez nem mindig igaz)
    - Snapshotok -> olyan összeállított csomag lista verziók, amely biztosan működni fognak egymással
    - `stack.yaml`-ben meg lehet mondani melyik snapshotot szeretnénk a használni a projektünkhöz
    - De el is térhetünk a snapshot által felajánlott csomagoktól és a stack meg próbálja függőségeket kezelni
  - Izolált, csak a projekten belül telepíti a csomagokat 
  
##### Használt Cabal csomagok
- base >= 4.7 && < 5
  - Haskell alap könyvtár, legalapvetőbb adatstruktúrák és nyelvi elemek
- text
  - Ez a Text adatstruktúra
- strict
- deepseq
- bytestring
- vector
  - Vector adatstruktúra
- containers
  - Különböző funkcionális adatstruktúrák, innen jön a sequence is.
- hashtables
  - Hasító táblák
- clock
  - Idő könyvtár
- array
- Unique
  - Néhány segítő függvény egyedi elemek, és duplikált elemek megtalálására listában

## Lox

Ez egy dinamikus típusosságot használó, imperatív, objektum orientált programozási nyelv, amelyben van némi funkcionális programozási nyelvi elem is.

### Szintaxis

#### Alaptípusok
##### Szám
- 64 bites lebegőpontos szám típus
- Jelölés: szám karakter, és pont, hogy ha lebegő pontos számot akarunk mutatni: `5`
- Csak decimális megjelenítés
- Alapműveletek:
  - Összeadás a `+` jellel: `5+1`
  - Kivonás: a `-` jellel: `5-1`
  - Szorzás a `*` jellel: `5*1`
  - Osztás: a `/` jellel: `25/5`
  - Negálás: a `-` jellel: `-5`
- Összehasonlítás:
  - Kisebb: a `<` jellel: `5 < 1` 
  - Kisebb vagy egyenlő, mint: a `<=` jellel: `5 <= 1`
  - Nagyobb: a `<` jellel: `5 > 1`
  - Nagyobb vagy egyenlő: a `>=` jellel: `5 >= 1`
  - Egyenlő: a `==` jellel: `5 == 1`
  
##### String
- Karakterlánc típus
- Jelölés: idézőjelek között karakterek sorozata: `"Hello, World!"`
- Alapműveletek:
  - Konkatenáció: `+` jellel: `"Hello, " + "World!"`
  
##### Nil
- "Null" érték megfelelője, ebben a nyelvben
- Az érték hiányát jelzi
- Jelölése: `nil`

##### Boolean
- Igaz és hamis érték reprezentációja
- Igaz: `true`
- Hamis: `false`
- Alapműveletek: 
  - Negálás: a `!` jellel: 
    - `!true //false`
    - `!false //true`
    - Negálni nem csak a `true` és `false` értéket lehet, hanem minden értéket is mint, nil, szám vagy karakter lánc
      - `nil` az hamis értékű, minden más pedig igaz értékű
      - Negálásnál a boolean értéket fogja eredményül adni
  - "És" és "Vagy" művelet
    - Hasonlóan a negáláshoz, nem csak boolean értékek lehetnek itt.
    - Viszont az értéként magát az eredeti értéket fogja adni, nem pedig a hozzátársított boolean értéket 
    - short-circuit
    - És:
      - `and` kulcsszó: `true and false`
    - Vagy:
      - `or` kulcsszó: `true or false`
  - ?: operátor
    - `a == 5 ? print "a egyenlő öt" : print "a nem egyenlő öt";`
    

#### Kifejezések
- A típusoknál kifejtett alapműveletek láncolata.
- Precedencia (!)

#### Utasítások
- Output, input beolvasása
- Állapotváltoztatás

##### A "print" utasítás
- A outputra való kiírást szolgálja
- A könyv írója fejlesztés egyszerűsítése végett építette bele a "print"-et, mint utasítást a nyelvbe, függvény hívás helyett 

##### Kifejezés utasítás
- Kifejezés, majd utána egy lezáró jel.
  - A lezáró jel: `;`
  - Példa: `"Ez egy utasítás, ami csak egy kifejezésből áll";`
##### Blokk utasítás
- Több utasítás egy blokkba való rendezése.
- Jele: `{}`
- Példa: `
  {
      5 + 6;
      print 5;
  }
`
#### Változó deklarációk
- változók létrehozása a `var` kulcsszóval
- Csak betűvel kezdődhet
- De számokat is tartalmazhat
- Ha nincs definiálva az értéke automatikusan null értéket kap
- Ha pedig a változó deklarálva van, akkor a változónévvel lehet hivatkozni rá.
 `
 var egy = 1;
 print egy // output: 1
 var nilVagyok;
 print nilVagyok // output: nil
 `

 - Scoping: ha van egy olyan változó, ami egy blokkon belül lett létrehozva és ugyanolyan nevű, mint egy a felette lévő scope-ban levő változó, akkor árnyékolni fogja azt
 
#### Elágazások és ciklusok
##### If és else
- az `if` kulcsszóval létrehozhatunk elágazást:
  `
  if (a == 5) {
      print a;
  }
  `
- az `else` kulcsszóval pedig "else" ágat hozhatunk létre
  `
  if (a == 5){
    print a;
  } else {
    print "Nem öt"  
  }
  `
##### Ciklusok
- for és while loop
- `for` és `while` kulcsszóval lehet létrehozni
- While: 
 `
var a = 1;
while (a < 10) {
  print a;
  a = a + 1;
}
 `

- For:
`
for (var a = 1; a < 10; a = a + 1) {
  print a;
}
`

#### Függvények
##### Deklaráció: 
`fun` kulcsszóval
`
fun printOne(){
    print 1;
}
`
- Paramétereket képes fogadni a zárójelek között
- `return` kulcsszóval lehet a függvényből visszatérni
`
fun add(a, b){
    return a+b;
}
`

##### Függvényhívás
- függvény nevével és zárójel, az zárójelben tudjuk átadni az argumentumokat
`
printOne();
add(2,3)`

##### Tulajdonságok
- Függvények támogatják a rekurziót

`
fun addOne(n){
    print n; 
    if (n == 5) {
        return n;
    } 
    return addOne(n+1);
} 
addOne(1);
`
- Függvényt át lehet adni, mint argumentumot (Higher order functions)

`
fun a(){print 5;}
fun b(f){
    f();
}
`

- Függvényt lehet a függvényen belül definiálni
- Függvénnyel visszalehet térni a `return` kulcsszóval, ha nincs `return`, akkor automatikusan `nil`-lel tér vissza 
- Támogatják a closure-t
- A függvényeket el lehet menteni egy változóba

`
fun makeCounter() {
    var i = 0; 
    fun count() {
        i = i + 1;
        print i;
    }
    return count;
}
var counter = makeCounter(); 
print counter(); //  
print counter();

// De ez is helyes:
makeCounter()();
`

#### Osztályok
- Klasszikus öröklődéses objektum orientált paradigmát követ a nyelv
- Egyszeres öröklődést támogat
- `.` operátorral érjük el az értékeket, és a metódusokat
- az `init` függvény lefut minden új objektum létrehozásakor
- A metódusokat a `fun` kulcsszó nélkül hozzuk létre.
- A példányváltozókat pedig 
  - vagy az `init` függvényben hozzuk létre, `this` osztályra mutató kulcsszó segítségével
  - vagy pedig a példány létrehozása után közvetlenül `.` operátorral ráhelyezzük
- A `<` jellel tudunk gyerek osztályt létrehozni
- `super` kulcsszóval érjük el az ősosztályt

`
class A{
  init(){
    this.name = "Hello";
  }
  cook(){
    print "cook";
  }
}

class B < A {
  init(){
    super.init();
  }
}

var c = B();
c.cook();
c.hello = "hello";
print c.name;
print c.hello;
`

- A `.` operátort lehet láncolni
`
class B{
  init(){
    this.name = "B";
  }
}

class A{
  init(){
    this.bClass = B();
    this.aName = "A";
  }
}
var a = A();
print a.bClass.name;
`

#### Komment írás

- a Komment írás történhet `//` jellel, ami csak sor komment lesz, vagy pedig `/*  */` jellel (két jel között lehet bármi), és az pedig egy blokk komment lesz

#### Beépített függvények (!clock implementáció újra gondolása)
- Egy függvény a `clock`, amivel az aktuális időt tudjuk lekérni
- És idő mérésre lehet használni a két hívást különbségét kiértékeljük

### jLox és hLox különbségei (!)
#### Aritás ellenőrzsé -> újra gondolni
#### Init
(!jLox-ban megnézni, miért nincs ez így implementálva)
- Én a hLoxban kötelelző tettem az `init` függvényt, mert mi van akkor, ha a ősosztálynak van `init` függvénye, de a gyerek osztálynak nincs
  1. Háttérben létrehozok egy init függvényt, aminek az aritása ugyanolyan, mint az ősosztálynak, de `nil` értékekkel vannak átadva az ősosztály `init`-jének
     - Ezt én úgy ítéltem, hogy a végfelhasználó számára zavaró lehet, hogy fogalma sincs, hogy honnan jönnek `nil` értékek
  2. Default értékű paraméterek
     - Ennek a létrehozását sok időnek itéltem
  3. Kötelező az init függvény:
     - Könnyű volt implementálni, és teljesen átlátható a felhasználónak
#### Error kezelés -> újra gondolni

## Lox feldolgozás részei
- Forrásfájl beolvasása
  - `Runners.hs`, ebben a fileban vannak azok a függvények, mely a forrásfájl beolvasását és feldolgozó függvények hívását végzik
- Szkennelés, tokenizálás
  - Az átadott forráskódból tokeneket hoz létre, amit később a parsernek átadunk, hogy AST-t építsen belőle.

## Forrásfájl beolvasása

### Közös részek

- `Main.hs` fájlban csak egy függvény található, ez pedig a `startFromTerminal`:
```haskell
main :: IO ()
main = startFromTerminal
```

- `Runners.hs` fájlben pedig megtalálhatók mindazok a függvények, amely a fájl beolvasását, vagy REPL-t végzik
  - Az első ilyen függvény a `startFromTerminal`
    - Összeszedi az shell argumentumokat
    - Meghívja a `startLox` függvényt
  
```haskell
startFromTerminal :: IO()
startFromTerminal = do
    args <- getArgs
    let newArgs = map T.pack args
    startLox newArgs
```

  - `startLox`
    - Ha nem kap paramétert, akkor meghívja a shellt
    - ha egy paramétert kap meghívja a fájlt feldolgozó függvényt
    - Ha ennél több argumentum van, akkor kiírja, hogy "Egy, vagy annál kevesebb kell használni"
  
```haskell
startLox :: [T.Text] -> IO ()
startLox args
  | argsLength == 1 = runLoxFile (head args)
  | argsLength > 1 = putStrLn "Use one or less args"
  | otherwise = runPrompt
  where argsLength = length args
```

  - Mind a `runLoxFile`, mind a `runPrompt` a `run` függvényt hívja meg
    - A `runPrompt` miután lefutott a `run`, újra meghívja magát, így kapunk egy REPL-t

```haskell
runLoxFile :: T.Text -> IO ()
runLoxFile arg = do
  text <- TIO.readFile (T.unpack arg)
  run text

runPrompt :: IO()
runPrompt = do
  input <- readFromRepl
  run (T.pack input)
  runPrompt

readFromRepl :: IO String
readFromRepl = putStr "Lox> "
     >> hFlush stdout
     >> getLine
```

- A `run` különböző féleképpen működik a két megoldásban

### Első megoldás

- A bejövő adat feldolgozását, és a következő lépés indítását, egy-egy függvény hívásával érjük el.
- Ezeket a lépéseknél mélyebben leírom

### Új megoldás

- Egy rövid rövid függvény elágazással, tanulva az előző koncepció bonyolultságából
- `HappyParser.hs` `happyParser` nevű függvénye az eredménye a happy parser használatának, ez végzi a Szkennelést és a Parsert is. A hibakezelést a happy forrásfájlban (happyParser.y) megtudjuk adni.
- Meghívjuk a rezolváló függvényt (resolveProgram)
  - Rezolváló függvényt végig futtatjuk és összeszedjuük, az összes felbukkanó hibát
  - Ha van benne hiba, akkor kiírjuk a hibákat, és befejezzük a futást
- Meghívjuk a Kiértékelő függvényt, ami le is futtatja a forráskód parancsait.
  - Ha bármi hiba történik a futáson belül, akkor a kiértékelés megszakad és kiírja a hiba okát.
```haskell
run :: T.Text -> IO()
run text = do
  let ast = H.happyParser (T.unpack text)
  resolverMeta <- resolveProgram ast
  if not (null (resolverErrors resolverMeta)) then do
    mapM_ print (resolverErrors resolverMeta)
  else do
    evalProgram (declarations resolverMeta) (variableVector resolverMeta)
    return ()

```

## Scanner/Lexer

### Első megoldás

#### Alaptípusok, amivel jellemezhetjük a tokeneket

- Tokentípus, ez mutatja, hogy pontosan milyen token
  - A látható `NOT_TOKEN` az minden olyan dolog, amit a scanner nem tudott felismerni.
  - `EOF` end-of-file

```haskell
data TokenType = LEFT_PAREN | RIGHT_PAREN | LEFT_BRACE | RIGHT_BRACE | 
    {-...-}
    EOF | NOT_TOKEN TextType deriving (Show, Eq, Ord)
```

- Token, igazából két értéket tárol, tokennek a típusát, és azt, hogy hányadik sorban található
  - Ezeknek a sorozatát, fogjuk átadni a parsernek
```haskell
data Token = Token {
tokenType :: TokenType
, line :: Int
} deriving Eq
```

#### Run
- Elsőként a `run` függvény fog meghívódni 
  - Meghívja a scanTokens nevűfüggvényt, ami visszaad egy token szekvenciát
  - Majd utána az error lekezelő, vagy parse hívó függvényt
  - Error kezelés: Ha talál olyan tokent, ami `NOT_TOKEN` típusú, akkor kiírja, hogy melyik token az, ami a hibát okozta, és ebben benne van, hogy melyik sorban történt az eset.
```haskell
run :: T.Text -> IO()
run text = do
  let tokens = scanTokens text
  printScanErrorOrContinue tokens
  
printScanErrorOrContinue :: S.Seq Token -> IO ()
printScanErrorOrContinue tokens = if null scanError then printResolveErrorOrContinue parsed else print scanError
  where scanError = S.filter (isNotToken . tokenType) tokens
        parsed = parse tokens
```


#### TokenReader: egy segítő adatstruktúra
- `createToken` függvény, igazából segítség, hogy könnyen létre lehessen hozni token típusú rekordokat
- a `len` a token hosszát adja meg (ezt arra haszáltam volna, hogy soron belül megadjam, hol a hiba)
- a `token` a token fajtája 

```haskell
data TokenReader = TokenReader {
len :: Int
, token :: TokenType
, numberOfNewLines :: Int
} deriving Show

createToken :: TokenType -> Int -> Int -> TokenReader
createToken tType tLength tNewLines = TokenReader {token=tType, len=tLength, numberOfNewLines=tNewLines}
```

#### scanTokens függvény

##### scanTokensWithData
- Első sorban meghívjuk a `scanTokensWithData` nevű belül definiált függvényt 
  - A paraméterül kapott indexszel megnézzük, hogy a beolvasott forrásfájl végén vagyunk-e
    - Ha igen, visszadjuk a Token szekvenciát (list), amit létrehoztunk
    - Ha nem:
      - `recognizeToken` fogja létrehozni a `tokenScanned` változót, ami egy `TokenReader` típusú rekord
      - Ennek hosszát lemérjük (lenP)
      - Elmentjük az új `Token`-t
        - Tokentype a TokenReaderből
        - line: sor amiben a token elhelyezkedik
      - Az indexet frissítjük (newCurrent)
      - Az új sor értéket felvesszük
        - Itt lesz a fontos az, hogy elmentettük, mennyi sort hozott létre az új token
        - Ezekkel az új adatokkal meghívjuk ugyanezt a függvényt
          - az új index
          - az új sorszám
          - az új szekvencia, amihez hozzáadjuk a létrehozott tokent
          - Az szöveg, amiből kivettük azokat a részeket, ami az új tokenhez tartozik 

```haskell
scanTokens :: T.Text -> S.Seq Token
scanTokens src = S.filter (\x -> tokenType x /= WHITE_SPACE && tokenType x /= COMMENT) (scanTokensWithData 0 1 S.empty src)
  where
    isAtEnd current = current == T.length src
    scanTokensWithData :: Int -> Int -> S.Seq Token -> T.Text -> S.Seq Token
    scanTokensWithData current lineP list text =
          let tokenScanned = recognizeToken text
              lenP = len tokenScanned
              tokenP = Token {tokenType= token tokenScanned, line=lineP}
              numberOfNewLinesP = numberOfNewLines tokenScanned
              newCurrent = current + lenP
              newLineNumber = lineP + numberOfNewLinesP
          in
            if isAtEnd current then list else scanTokensWithData newCurrent newLineNumber ((S.|>) list tokenP) (T.drop lenP text)
```

##### recognizeToken
- Ez hozza létre  a `tokenScanned` változót, amit a `recognizeToken` nevű függvénnyel hozunk létre
  - Ez egy óriási switch case, ami létrehozza a tokeneket
  - Itt lerövidítettem, de a teljes kód olvasható github oldalamon
  
```haskell
recognizeToken :: T.Text -> TokenReader
recognizeToken text
  | tok == ")" = createNoNewLineToken RIGHT_PAREN 1
  | tok == "(" = createNoNewLineToken LEFT_PAREN 1
  | tok == "}" = createNoNewLineToken RIGHT_BRACE 1
  {- ... -}
  | tok == "!" = checkIfTwoLengthToken twoTok "!=" BANG_EQUAL BANG
  | tok == "=" = checkIfTwoLengthToken twoTok "==" EQUAL_EQUAL EQUAL
  | tok == "<" = checkIfTwoLengthToken twoTok "<=" LESS_EQUAL LESS
  | tok == ">" = checkIfTwoLengthToken twoTok ">=" GREATER_EQUAL GREATER
  | tok == "/" = checkIfCommentOrDivision text
  | tok == " " = handleWhiteSpace
  | tok == "\t" = handleWhiteSpace
  | tok == "\n" = createNewLine
  | tok == "\"" = createString text
  | isDigit (T.head tok) = createNumber text
  | isAlpha (T.head tok) = createIdentifier text
  | otherwise = createNoNewLineToken (NOT_TOKEN tok) 1
  where tok = T.take 1 text 
        twoTok = T.take 2 text 
```
    - További függvények amiket meghív:
      - `createNoNewLineToken` olyan token létrehozása, ami nem hoz létre új sort
        - Az első paramétere azt mondja meg milyen tokent, hoz létre, második meg, hogy milyen hosszú lesz a token
      - `checkcheckIfTwoLengthToken` megnézi, hogy ha még egy karaktert hozzáveszünk a elkészítendő tokenhez, akkor másik token lesz-e belőle vagy sem
      - `handleWhiteSpace` lértrehoz egy whitespace tokent (space, tab)
      - `createNewLine` létrehoz egy új sor tokent (whitespace, de van új sor)
      - `checkIfCommentOrDivision` itt megnézi, hogy a "/" jel, csak az osztáshoz tartozik, vagy pedig "//" vagy "/*" ami mindakettő kommentet jelöl
      - `createString`, karakter sorozat létrehozása
      - `createIdentifier`, pedig kulcsszavak vagy azonosítók létrehozására szolgál
        - `createIdentifierChunk`, az gyakorlatilag létrehoz egy identifiert, amibe lehetnek betűk és számok is
        - `createKeyword`, egy új `TokenReader`-t hoz létre
      
```haskell
createIdentifier :: T.Text -> TokenReader
createIdentifier text
  | chunk == "and" = createKeyWord AND
  | chunk == "or" = createKeyWord OR
  | chunk == "if" = createKeyWord IF
  {-...-}
  | chunk == "while" = createKeyWord WHILE
  | otherwise = createNoNewLineToken (IDENTIFIER chunk) (T.length chunk)
  where chunk = createIdentifierChunk text
```



