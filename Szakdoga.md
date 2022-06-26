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

### AST (Abstract Syntax Tree) (!)

Absztrakt Szintaktikai fa: Fa reprezentációja egy szöveg struktúrájának.
- Absztrakt, abból a szempontból, hogy nem jeleníti meg minden apró részletét az igazi szintaxisnak, csak a struktúrális és tartalmi részeket

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
- függvény nevével és zárójel, az zárójelben tudjuk átadni az argumentumokat, amelyek kifejezések lehetnek
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

### Művelet precedencia és asszociativitás

- A tetején a legkisebb precedenciájú művelet
- Alján meg a legnagyobb

|     Művelet    | Asszociativitás | Operandusok száma |
|----------------|-----------------|-------------------|
|        =       |      jobb       |         2         |
|       ? :      |      nincs      |         3         |
|     and/or     |      bal        |         2         |
|      ==/!=     |      bal        |         2         |
|    > < >= <=   |      bal        |         2         |
|       + -      |      bal        |         2         |
|       * /      |      bal        |         2         |
|       ! -      |      jobb       |         1         |
| függvény hívás |       -         |         -         |


### jLox és hLox különbségei (!)
#### Aritás ellenőrzés -> újra gondolni
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
  - A happyParsernél, `String` típus használtam a lexernél/scannernél, de ott az jól működik 
- Meghívjuk a rezolváló függvényt (resolveProgram)
  - Rezolváló függvényt végig futtatjuk és összeszedjük, az összes felbukkanó hibát
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

### Első megoldás (Scanner.hs)

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

- Meghívja a scanTokensWithData függvényt, ami végig megy a beolvasott forrás szövegen létrehozva a token szekvenciát
- Ezt le szűrjük, kiszedjük belőle a `WHITE_SPACE` és `COMMENT` típusú tokeneket
  - Az adatok megtartása végett (token hossz, mennyi sort foglal el), hozzuk létre a `WHITE_SPACE` és `COMMENT` típusú tokeneket

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
  - Ez egy óriási pattern matching, ami létrehozza a tokeneket
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

### Az új megoldás

#### Alaptípusok
- Tokentípus, hasonló az előzőekben ismertetett TokenType-hoz
```haskell
data Token =  LEFT_PAREN | RIGHT_PAREN | LEFT_BRACE | RIGHT_BRACE |
    {-...-}
    deriving (Show, Eq, Ord)
```

#### lexer

- Ennél a megoldásnál kihasználom, a haskell lista működését
  - Minden lexer hívás végén csinálok egy `TOKEN : lexer cs` hívást, ebből pedig, további `TOKEN : lexer cs` hívások lesznek, amik a legvégén, amikor elfogy a beolvasott szöveg akkor `TOKEN : TOKEN : ... : TOKEN : []`, válik, ami létrehozza a token listát
- Hasonlóan az előző megoldáshoz, ez is egy nagy pattern matching

```haskell
lexer :: String -> [Token]
lexer (c:cs)
      | isSpace c = lexer cs
      | isAlpha c = lexKeyword (c:cs)
      | isDigit c = lexNum (c:cs)
lexer ('=':cs) = lexHandleEqual cs
lexer ('!':cs) = lexHandleBang cs
lexer ('<': cs) = lexHandleLess cs
lexer ('>': cs) = lexHandleGreater cs
lexer ('/':cs) = lexHandleSlash cs
lexer ('+':cs) = PLUS : lexer cs
lexer ('-':cs) = MINUS : lexer cs
{-...-}
lexer ('\"': cs) = lexString cs
lexer (_:cs) = lexer cs
lexer [] = []

lexNum :: String -> [Token]
lexNum cs = NUMBER (read num) : lexer rest
      where (num,rest) = span isDigit cs

lexKeyword :: String -> [Token]
lexKeyword cs =
   case span (\x -> isAlpha x || isDigit x) cs of
      ("var",rest) -> VAR : lexer rest
      ("true", rest) -> TRUE : lexer rest
      {-...-}
      (var,rest)   -> IDENTIFIER (T.pack var) : lexer rest
```

- Ezt a függvényt a happyParser-en belül hívjuk meg
  - ami, így néz ki: `happyParser = parser . lexer`


## Parser

### Descent Parser és LR bemutatása

#### Descent Parser
- Felülről lefelé parser
- A legkisebb precedenciájú műveleteket keresi először, ha talál, akkor leválasztja az előtte lévő részt, és abban keres magasabb precedenciájú műveletet

#### LR


### Első megoldás

#### Alaptípusok

##### AST
- AST.hs-ben található az összes típus, amit használtam a fejlesztés során
- Itt nem fogom az összes típust felsorolni csak ízelítőt akarok adni, hogy milyen jellegű adatstruktúrában tároltam a különböző nyelvi elemeket.

- Látható az alábbi példában, hogy a program deklarációk sorozatából épül fel.
- Ezen belül a `DECLARATION` type definiálja milyen jellegű, deklarációk lehetnek a programon belül
  - itt láthatjuk, hogy megadtam a `instance Show DECLARATION` typeclasst, amivel definiálom mit írjon ki az outputra, ha kiíratom ezeket, nagyrésze csak számomra volt a könnyebb fejlesztés érdekében, de a `PARSE_ERROR`-nál pedig ezt használom, hogy a felhasználónak Parser hibaüzeneteket írja ki.
  - Az `S.Seq Token` használata a típusoknál is a könnyebb fejlesztés miatt volt, kivéve a `PARSE_ERROR` típusnál
- `VARIABLE_DECLARATION` type-nál, ami érdekes, az az ID, amit a parse-nél már hozzáadok a változóhoz, és az új megoldásban pedig azt a resolverre bízom, ez majd segít a kilrtlkelésnél minden olyan változónál, amit nem függvényen belül hoztak létre.
  - Ezt majd a resolver-nél tárgyalom 
  - Ennek párjaként a `LITERAL` `IDENTIFIER` típusánál is van egy ID, ami segít a kiértékelésnél
- Ebben érdekességképen a `CALL` `S.Seq ARGUMENTS` van ami maga is egy szekvencia
  - Ez az első próbálkozás arra, hogy megoldjam a `fuggveny(a,b)(c,d,e)(f)` jellegű kifejezéseket

```haskell
newtype PROGRAM = PROG (S.Seq DECLARATION)
instance Show PROGRAM where
  show (PROG x) = show x

data DECLARATION = DEC_STMT STATEMENT | DEC_VAR VARIABLE_DECLARATION | DEC_FUNC FUNCTION_DECLARATION | DEC_CLASS CLASS_DECLARATION | PARSE_ERROR TextType (S.Seq Token) | SKIP_DEC deriving Eq

instance Show DECLARATION where
  show (DEC_STMT x) = show x
  show (DEC_VAR x) = show x
  show (PARSE_ERROR errMsg tokens) = mconcat ["ParseError: ", show errMsg, ". In line: " ,show (line (S.index tokens (S.length tokens-1)))]
  {-...-}

data VARIABLE_DECLARATION = VAR_DEC_DEF IDENTIFIER EXPRESSION (S.Seq Token) ID | VAR_DEC IDENTIFIER (S.Seq Token) ID | VAR_DEF IDENTIFIER EXPRESSION (S.Seq Token) ID | PARAM_DEC IDENTIFIER (S.Seq Token) ID deriving Eq
instance Show VARIABLE_DECLARATION where
  show (VAR_DEC_DEF iden expr _ id) = mconcat ["var", " ", show iden, " = ", show expr, ";id: ", show id]
  {-...-}

data STATEMENT = EXPR_STMT EXPRESSION 
               | PRINT_STMT EXPRESSION 
               | BLOCK_STMT (S.Seq DECLARATION)
               | IF_STMT EXPRESSION STATEMENT 
               | IF_ELSE_STMT EXPRESSION STATEMENT STATEMENT
               | WHILE_STMT EXPRESSION STATEMENT
               | FOR_STMT DECLARATION EXPRESSION DECLARATION STATEMENT
               | LOOP EXPRESSION DECLARATION STATEMENT
               | RETURN_NIL | RETURN EXPRESSION deriving Eq
{-...-}
data EXPRESSION = EXP_LITERAL LITERAL 
                | EXP_UNARY UNARY (S.Seq Token) 
                | EXP_BINARY BINARY (S.Seq Token) 
                | EXP_TERNARY TERNARY (S.Seq Token) 
                | EXP_GROUPING GROUPING
                | EXP_CALL CALL
                | NON_EXP String (S.Seq Token) deriving Eq
                
data LITERAL = NUMBER Double | STRING TextType | TRUE | FALSE | NIL | IDENTIFIER TextType (S.Seq Token) ID deriving Eq
{-...-}
data CALL = CALL_FUNC EXPRESSION (S.Seq ARGUMENTS) ID deriving Eq
{-...-}
data BINARY = BIN EXPRESSION OPERATOR EXPRESSION deriving Eq
{-...-}
data TERNARY = TERN EXPRESSION OPERATOR EXPRESSION OPERATOR EXPRESSION deriving Eq  
{-...-}
data ARGUMENTS = ARGS (S.Seq EXPRESSION) | INVALID_ARGS TextType (S.Seq Token) deriving Eq
{-...-}
data OPERATOR = EQUAL_EQUAL | BANG_EQUAL | LESS | LESS_EQUAL | GREATER | GREATER_EQUAL
               | PLUS  | MINUS | STAR | SLASH | QUESTION_MARK | COLON | BANG | AND | OR deriving Eq

```

##### ParserMeta

Segéd adatstruktúra, amiben elmentettem a jelenlegi állapotát a parsernek.

- `declaration`: a elkészített deklaráció
- `tokensLeft`: a deklaráció elkészítése után maradt tokenek
- `currentVarId`: Ez az a változó, ami tárolja, hogy jelenleg melyik változó azonosítónál járunk
  - Ez az azonosító, arra lesz jó, hogy az Eval-nál könnyebb lesz megtalálni az olyan változókat, melyek nincsenek closure-ben. Erre a rezolvációnal létrehozok egy tömböt, amiben gyorsan tudom keresni az adatokat, és az Evalnál, meg segít a megtalálsban és frissítésében

Nem fogom az összes segéd függvényt felsorolni de kettőt érdemes hozzá adni:
- `createParserMeta`: Ez hozza létre a meta objektumot, ami érdekes, hogy az első deklarációt üresnek inicializálja
- `updateParserMeta`: Ez frissíti az új adatokkal a meta objektumot

```haskell
data ParserMeta = ParserMeta {
    declaration :: DECLARATION
  , tokensLeft :: S.Seq Token
  , currentVarId :: Int
  }
  

createParserMeta :: S.Seq Token -> ParserMeta
createParserMeta tokens = ParserMeta{declaration=SKIP_DEC, tokensLeft=tokens, currentVarId=0} 


updateParserMeta :: DECLARATION -> S.Seq Token -> Int -> ParserMeta -> ParserMeta
updateParserMeta dec tokens cVarId meta = meta{declaration=dec, tokensLeft=tokens, currentVarId=cVarId} 
```

#### Parser

A legfőbb függvények itt láthatók a parsernek
Ami itt látszik, az, hogy a `createDeclarations` megnézi, hogy el fogyasztottuk-e az összes tokent, vagy hibára futottunk, ekkor kilép
Ha pedig nem akkor `createDeclaration` hívódik meg ami ellenőrzi az első elemet, és ez alapján fogja feldolgozni a tokeneket
Ennél kihasználtam azt, hogy az első kulcsszó kvázi determinálja, hogy milyen jellegű lesz a deklaráció alakja.
Ha az első kulcsszó például `class` akkor osztályként kezdi el kezelni, és aszerint keresi meg a megfelelő nyelvi elemeket, ha ez nem sikerül, akkor parse error és egy szinkronizációt is végez.

A szinkronizáció az a művelet, ahol egy hibára futás után egy nyelvi elemet keresve visszapróbáljuk állítani egy olyan állapotra, ami utána tovább feldolgozható.

```haskell
parse :: S.Seq Token -> PROGRAM
parse = createProgram

createProgram :: S.Seq Token -> PROGRAM
createProgram tokens = PROG (createDeclarations (createParserMeta tokens) S.empty)

createDeclarations :: ParserMeta -> S.Seq DECLARATION -> S.Seq DECLARATION
createDeclarations meta decSeq
  | isLastParseError || S.null (tokensLeft meta) = S.drop 1 (decSeq S.|> dec)
  | otherwise = createDeclarations newMeta (decSeq S.|> dec)
  where isLastParseError = (isParseError <$> getLast decSeq) == Just True
        newMeta = createDeclaration meta
        dec = declaration meta
        
createDeclaration :: ParserMeta -> ParserMeta
createDeclaration meta
  | isIf = handleIf meta
  | isWhile = handleWhile meta
  | isFor = handleFor meta
  | isFunction = handleFunction meta
  | isReturn = handleReturmeta
  | isBlockDec = handleBlock meta
  | isClass = handleClass meta
  | otherwise = handleSimpleDeclaration meta
  where firstToken = S.lookup 0 (tokensLeft meta)
        firstTokenType = tokenType <$> firstToken
        secondToken = S.lookup 1 (tokensLeft meta)
        secondTokenType = tokenType <$> secondToken
        isIf = firstTokenType == Just IF
        isBlockDec = firstTokenType == Just LEFT_BRACE
        isWhile = firstTokenType == Just WHILE
        isFor = firstTokenType == Just FOR
        isFunction = firstTokenType == Just FUN
        isReturn = firstTokenType == Just TokenHelper.RETURN
        isClass = firstTokenType == Just CLASS
        
synchronize :: S.Seq Token -> (S.Seq Token, S.Seq Token)
synchronize tokens = if isJust maybeIndex then S.splitAt (fromJust maybeIndex) tokens else (tokens, S.empty)
  where syncFunc = S.findIndexL (\x -> tokenType x `elem` [CLASS, FUN, VAR, FOR, IF, WHILE, PRINT, TokenHelper.RETURN])
        startIndex = syncFunc tokens
        maybeIndex = if startIndex == Just 0 then syncFunc (S.drop 1 tokens) else startIndex

```

Nem fogom minden parsert, amit létrehoztam bemutatni, mert nagyon sok idő lenne, csak néhányat, és bemutatni, hogy miért volt nehezen fenntartható a fejlesztés
- Amit fontos látni, az az, hogy feltételezem, hogy egy függvény jellegű nyelvi elemet kapok, így aszerint próbálom mintailleszteni minden egyes függvényben lévő element. Ha sikerül, feldolgozom a benne lévő nyelvi elemeket, és létrehozom az új deklarációt az `id`-val együtt. Ha nem, akkor hibát mentek el.
- Fontos itt látni, hogy előbb dolgozom fel a benne lévő elemeket, így azok előbb kapnak `id` értéket, mint a függvény
- Teljesség kedvéért hozzáadtam a blokk feldolgozást is, de az igazából igencsak egyértelmű:
  - Ha van a nyitóhoz záró, akkor feldolgozzuk a benne lévő deklarációkat, és elmentjük az új Deklarációba, ami egy Block statement, ami tartalmazza, az új benne feldolgozott deklarációkat 

Sorrend:
- Tudjuk, hogy függvény mert a `fun` kulcsszóra mintaillesztettünk
- Ha nincs azonosító név, vagyis valami más van helyette ott ahol gondolnánk, akkor hiba mert az egy hibásan megírt függvény
- Ha van, akkor zárójelet keresünk, és ha megtaláljuk a párjával együtt, akkor a benne lévő elemekre tudjuk, hogy csak paraméterek lehetnek, ezért `handleBuildParams` függvényt hívjuk meg.
- Itt egy "érdekes" design döntést hoztam meg, amit utólag nézve nem gondolom, hogy egy jó ötlet volt: Ha paraméter feldolgozó függvény elhasal, nem próbálom meg parse hibaként beállítani, hanem csak berakok egy `Invalid Parameter` type-ot, és nem kezdek vele semmit itt, ahelyett, hogy itt a függvény készítésben lekezelném, és parse hibát készítenék belőle. Persze akkor a függvény feldolgozásba még több elágazás lett volna.
- Ha ez megvan a függvény blokkot dolgozom fel, amit először belewrappelek egy declarationbe és utána dolgozom fel a `createDeclaration`-nel. Ebből kiszedem a feldologzott blokkot, ha van a blokkon belül hiba azt felhozom a függvénybe, és ParseError-ként mentem



```haskell
handleFunction :: ParserMeta -> ParserMeta
handleFunction meta
  | not isIden = updateDecAndTokens (PARSE_ERROR "Identifier is missing after 'fun' keyword" err) rest meta
  | not isLeftParen = updateDecAndTokens (PARSE_ERROR "Parenthesis should be after function header" err) rest meta
  | not isRightParen = updateDecAndTokens (PARSE_ERROR "Parenthesis is not closed" err) rest meta
  | isNothing stmt = updateDecAndTokens (PARSE_ERROR "Parse error on block" err) rest meta
  | otherwise = updateParserMeta (DEC_FUNC (FUNC_DEC (fromJust maybeIdenType) params (FUNC_STMT (fromJust stmt)) (LOCAL_ID id))) funRest (id+1) newPMF
  where id = currentVarId meta
        tokens = tokensLeft meta
        maybeIden = S.lookup 1 tokens
        maybeIdenType = tokenType <$> maybeIden
        isIden = (ParseExpressions.isIdentifier <$> maybeIdenType) == Just True
        maybeLeftParen = S.lookup 2 tokens
        isLeftParen = (tokenType <$> maybeLeftParen) == Just LEFT_PAREN
        rightParenIndex = S.findIndexL (tokenIsType RIGHT_PAREN) (S.drop 3 tokens)
        isRightParen = isJust rightParenIndex
        paramTokens = S.drop 3 (S.takeWhileL (not . tokenIsType RIGHT_PAREN) tokens)
        params = handleBuildParams paramTokens (PARAMETERS S.empty paramTokens)
        stmtRest = S.drop 1 (S.dropWhileL (not . tokenIsType RIGHT_PAREN) tokens)
        newPMF = createDeclaration (updateTokens stmtRest meta)
        dec = declaration newPMF
        funRest = tokensLeft newPMF
        stmt = getStmtFromDec dec
        (err, rest) = synchronize tokens
        
handleBuildParams :: S.Seq Token -> PARAMETERS -> PARAMETERS
handleBuildParams tokens (PARAMETERS idens paramTokens)
 | S.null tokens = PARAMETERS idens tokens
 | S.null idenTokens = INVALID_PARAMS "Empty parameter" paramTokens
 | not isIden = INVALID_PARAMS "Parameters can only be identifiers" paramTokens
 | otherwise = handleBuildParams rest (PARAMETERS (idens S.|> newIden) paramTokens)
 where idenTokens = S.takeWhileL (not . tokenIsType COMMA) tokens
       maybeIden = tokenType (S.index idenTokens 0)
       isIden = ParseExpressions.isIdentifier maybeIden
       newIden = DEC_VAR (PARAM_DEC (tokenType (S.index idenTokens 0)) idenTokens PARAM)
       rest = S.drop (S.length idenTokens+1) tokens

handleBlock :: ParserMeta -> ParserMeta
handleBlock meta
  | isClosed = updateDecAndTokens (DEC_STMT (BLOCK_STMT (createDeclarations (updateTokens innerDecTokens meta) S.empty))) right meta
  | otherwise = updateDecAndTokens (PARSE_ERROR "Block is not closed" tokens) right meta
  where tokens = tokensLeft meta
        index = findMatchingBraceIndex tokens
        isClosed = isJust index
        (left, right) = if isJust index then S.splitAt (fromJust index+1) tokens else synchronize tokens
        innerDecTokens = S.drop 1 (S.take (fromJust index) left)

```


Itt is hasonló a logika, a "binary" operátor nyelvi elemeit próbálom darabjaiban mintailleszteni, majd pedig a benne operandusokat feldolgozni, miután feldolgoztam, létre hozom a "binary" operátort
- Itt ami érdekesebb, az maga a generalizálása a logikának, mivel 5-ször végeztem el majdnem teljesen ugyanazt a műveletet, így kihoztam a közös logikát egy függvénybe, és meghívtam a megfelelő
- Ami itt nehezebben látható és meggondolandó, hogy ez egy `Expression`, mivel egy `Expression` nem lehet végtelen hosszú, és mindig egy véges deklaráción belül helyezkedik el, amit lezár egy pontos vessző.
- Vegyük a `2+3*4 > 15 > 4+2;` kifejezést
- Precedenciák: 15, 4, 3*, 2+, >
- Először az `createLogic` (`and`,`or`), utána a `createEquality` (`==`), majd a `createComparison`(`>`-`<`), `createTerm`(`+`,`-`),createFactor(`*`-`/`)
- Először lefut az `createLogic`, nincs benne a sajátja, így meghívja a nextPrec-et, ami a `createEquality` és mivel az sincs benne, így az meghívja a nextPrec-et, `createComparison`.
- Ez megtalálja az első jelet, ami hozzá tartozik, így felbontja a kifejezést `2+3*4` és `15 > 4+2` műveletre az `>` operáció mentén. Az első részre mivel tudjuk, hogy csak magasabb precedenciájú lehet benne, ezért meghívja a `nextPrec` függvényt, ami a `createTerm` lesz ebben az esetben.
- Majd a meghívja a `thisPrec`-et pedig a második - a maradék, mivel több is lehet - részre, így elértük, azt, a bal asszociatív a művelet
- Igazából a második rész is hasonlóan fut, mint az egész, csak itt a művelet már csak `15 > 4+2`, így bontja `15`-re és `4+2`-re, és folytatódik hasnlóan
- Folytassuk a `createTerm`-mel, az megkapta a `2+3*4` kifejezést, bontjuk `2`-re és `3*4`-re, és itt is az elsőről tudjuk, hogy magasabb rendű, ezért nextPrec-cel (`createFactor`-ral) meghívjuk, majd pedig a második részre - `3*4` - meghívjuk a thisPrec-et (`createTerm`-et) és abban nem találunk, összeadás vagy kivonást, meghívjuk rá a következőt precedenciájút.
- Igazából ez a Recursive Descent logika lényege, ami ezeken a kisebb nyelvi elemeken nagyon jól működik a magasabb nyelvi elemekre már nehézkessé válik (legalábbis, úgy, ahogy én írtam).

- És itt a hasonlóan rossz megoldásom a argumentumok kezelése, ami tükrözi a paraméter kezelést




```haskell
createBinaryExpressions :: M.Map TokenType OPERATOR -> (S.Seq Token -> (EXPRESSION, S.Seq Token)) -> (S.Seq Token -> (EXPRESSION, S.Seq Token)) -> S.Seq Token -> (EXPRESSION, S.Seq Token)
createBinaryExpressions tokenExpMap thisPrec nextPrec tokens
  | S.null firstRest || isNothing maybeOp = (firstExpr, firstRest)
  | otherwise = ((EXP_BINARY (BIN firstExpr op secondExpr) tokens), secondRest)
  where (firstExpr, firstRest) = nextPrec tokens
        maybeOp = M.lookup (tokenType $ S.index firstRest 0) tokenExpMap
        op = fromJust maybeOp
        (secondExpr, secondRest) = thisPrec (S.drop 1 firstRest)

createLogic :: S.Seq Token -> (EXPRESSION, S.Seq Token)
createLogic = createBinaryExpressions (M.fromList [(TokenHelper.AND, AST.AND), 
                                                   (TokenHelper.OR, AST.OR)]) createLogic createEquality

createEquality :: S.Seq Token -> (EXPRESSION, S.Seq Token)
createEquality = createBinaryExpressions (M.fromList [(TokenHelper.EQUAL_EQUAL, AST.EQUAL_EQUAL), 
                                                      (TokenHelper.BANG_EQUAL, AST.BANG_EQUAL)]) createEquality createComparison

-- Should create a PARSE_WARNING type, when arguments are more than 255
buildArgs :: S.Seq Token -> S.Seq EXPRESSION -> ARGUMENTS
buildArgs tokens exprs
 | S.null tokens = ARGS exprs
 | S.null exprTokens = INVALID_ARGS "Empty argument" tokens
 | otherwise = buildArgs rest (exprs S.|> newExpr)
 where exprTokens = S.takeWhileL (not . tokenIsType COMMA) tokens
       newExpr = createExpression exprTokens
       rest = S.drop (S.length exprTokens+1) tokens

```
### Második megoldás

#### Alaptípusok

##### AST
Hasonló felépítés mint az előzőnél, de itt külön választottam a Rezolválás előtti és utáni adattípusokat
Itt nem sikerült dönteni teljes szétválasztás és összeolvasztás között, szóval, van ami együtt van (Rezolválás előtti és utáni), de valamelyik meg külön
- A függvények deklarációnál és a változó deklarációnál jól látható a dilemma, míg a függvényeknél nem volt probléma, hogy együtt kezeljem a kettőt, a változóknál, már zavaró volt a sok különféle, rezolvált és nem rezolvált változó.
- Itt fontos, hogy a parser nem végzi el a besorolást és id adást, (vagyis az előző megoldásban félig-meddig volt ott megoldva), hanem a rezolver fogja ezeket kezelni.
- Látható, hogy jobban elkülönül a függvény scope-ban deklarált változó (`R_` előjel) és a nem függvény scope-ban (`RC_`) deklarált változó.
- Hasonlóan van a `R_` mint az előző, esetben. Kap egy ID-t amivel, majd könnyedén lehet a Evalban címezi, és frissíteni az értékét. Ezt a rezolverben hozom létre, és adom át az Evalnak. 

- Ami új az a `Chain expression`, ami gyakorlatilag a "dot" operátor, hogy könnyen el lehessen érni különböző osztály példányain belül az értékeket. 
  - `this`, `super`, függvény hívás (ami egy példányosít egy osztályt) vagy a példány azonosítója (megint csak rezolvált verzók is vannak itt) lehet a kezdő érték.
  - a láncon belül lehet metódus hívás vagy attribútum lekérés 
- A `CALL` felépítése, pedig nem egy argumentum listák, listája, hanem függvény hívások listája. Theát `függvény[(a,b)][(c,d)]` -> `((függvény(a,b))(c,d))`
- Az előző megoldáshoz képest megszűntek az operációk, és helyette új típusokat hoztam létre. Ezt így másodjára jobban átláthatóbbnak látom.
- Ami itt érdekes, az, hogy még nem implementáltam a chain deklarációt, sem parser, sem típus szintjén. Ami igazából egy "Quality of Life" változtatás lenne.


```haskell
newtype PROGRAM = PROG [DECLARATION]
instance Show PROGRAM where
  show (PROG x) = show x

data DECLARATION = DEC_STMT STATEMENT | DEC_VAR VARIABLE_DECLARATION | R_DEC_VAR RESOLVED_VARIABLE_DECLARATION | DEC_FUNC FUNCTION_DECLARATION | DEC_CLASS CLASS_DECLARATION | R_DEC_CLASS RESOLVED_CLASS_DECLARATION | EMPTY_DEC deriving Eq

type IDENTIFIER = TextType
type PARAMETER = TextType

-- VAR_DEC_DEF: var a = 5;
-- VAR_DEC: var a;
-- VAR_DEF: a = 5;
-- PARAM: fun func(a){}
-- CLASS_VAR_DEF: A.a = 5; (A is instance of class)
-- THIS_VAR_DEF: this.a = 5;
-- IMPROVE: It does not support smth like -> A().bClass.name = 5; , but you can do -> var a = A().bClass; a.name = 5; 
data VARIABLE_DECLARATION = VAR_DEC_DEF IDENTIFIER EXPRESSION
                          | VAR_DEC IDENTIFIER
                          | VAR_DEF IDENTIFIER EXPRESSION
                          | PARAM IDENTIFIER
                          | CLASS_VAR_DEF IDENTIFIER IDENTIFIER EXPRESSION
                          | THIS_VAR_DEF IDENTIFIER EXPRESSION
                          deriving Eq

-- same as VARIABLE_DECLARATION, but it is resolveed
-- R_ -> it is resolved with an index
-- RC_ -> it is resolved in closure
data RESOLVED_VARIABLE_DECLARATION = R_VAR_DEC_DEF IDENTIFIER EXPRESSION ID 
                                   | R_VAR_DEC IDENTIFIER ID 
                                   | R_VAR_DEF IDENTIFIER EXPRESSION ID
                                   | R_CLASS_VAR_DEF IDENTIFIER IDENTIFIER EXPRESSION ID
                                   | RC_THIS_VAR_DEF IDENTIFIER EXPRESSION
                                   | RC_VAR_DEC_DEF IDENTIFIER EXPRESSION
                                   | RC_VAR_DEC IDENTIFIER
                                   | RC_VAR_DEF IDENTIFIER EXPRESSION
                                   | RC_CLASS_VAR_DEF IDENTIFIER IDENTIFIER EXPRESSION
                                   deriving Eq


-- FUNC_DEC: fun func(a,b){...} -> func is IDENTIFIER, a,b is [DECLARATION], function body is STATEMENT (and the parser only lets block statements)
-- R_FUNC_DEC: same as FUNC_DEC, but it is resolved and has an id
-- RC_FUNC_DEC: same as FUNC_DEC, but it is resolved, and in closure
-- METHOD: in class: func(a,b){...}
-- NATIVE_FUNC: Used to create AST nodes of native functions
-- R_ -> it is resolved with an index
-- RC_ -> it is resolved in closure
data FUNCTION_DECLARATION = FUNC_DEC IDENTIFIER [DECLARATION] STATEMENT
                          | R_FUNC_DEC IDENTIFIER [DECLARATION] STATEMENT ID
                          | RC_FUNC_DEC IDENTIFIER [DECLARATION] STATEMENT
                          | METHOD_DEC IDENTIFIER [DECLARATION] STATEMENT
                          | NATIVE_FUNC IDENTIFIER [DECLARATION] ID
                          deriving Eq


-- CALL: func(5,6+1);
-- R_CALL: call resolved as indexed
-- RC_CALL: call resolved as closure
-- CALL_MULTI: recursive type: func1(1,2)(3,4)(5,6) -> CALL_MULTI (CALL_MULTI (CALL func1 [1,2]) [3,4]) [5,6] from the parser 
data CALL = CALL IDENTIFIER [ARGUMENT] | R_CALL IDENTIFIER [ARGUMENT] ID | RC_CALL IDENTIFIER [ARGUMENT] | CALL_MULTI CALL [ARGUMENT] deriving Eq
instance Show CALL where
  show (CALL lit args) = mconcat [show lit, "(", show args, ")"]
  show (R_CALL lit args id) = mconcat [show lit, "(", show args, ")", " ", show id]
  show (RC_CALL lit args) = mconcat [show lit, "(", show args, ")"]
  show (CALL_MULTI call args) = mconcat [ show call, "(", show args, ")"]
  
-- CHAIN data structure: list but the first and last element CAN be IDENTIFIERs, and this and super can only be first 
-- a().b().c()
-- this.a
-- this.b()
-- super.a()
-- A().bClass.name;
-- Not all calls and identifiers are resolved, those in the tail if the chain are not resolved, they will be handle in eval (they will use the result of the chain link before them)
data CHAIN_LINK = LINK_CALL CALL | LINK_IDENTIFIER IDENTIFIER | R_LINK_IDENTIFIER IDENTIFIER ID | RC_LINK_IDENTIFIER IDENTIFIER | LINK_THIS | LINK_SUPER deriving Eq
instance Show CHAIN_LINK where
  show (LINK_CALL x) = show x
  show (LINK_IDENTIFIER x) = show x
  show (R_LINK_IDENTIFIER x _) = show x
  show (RC_LINK_IDENTIFIER x) = show x
  show LINK_THIS = "this"
  show LINK_SUPER = "super"

newtype CHAIN = CHAIN [CHAIN_LINK] deriving Eq
instance Show CHAIN where
  show (CHAIN links) = mconcat $ reverse $ foldl (\y x -> mconcat [show x, "."] : y) [] links
  
  
-- UNARY_NEGATE: logical negate: !true -> false
-- UNARY_MINUS: numerical negate: -5
data UNARY = UNARY_NEGATE EXPRESSION |
             UNARY_MINUS EXPRESSION
             deriving Eq
instance Show UNARY where 
  show (UNARY_NEGATE x) = mconcat ["!", show x]
  show (UNARY_MINUS x) = mconcat ["-", show x]


data BINARY = BIN_ADD EXPRESSION EXPRESSION |
              BIN_SUB EXPRESSION EXPRESSION |
              {-...-}
              BIN_OR EXPRESSION EXPRESSION
              deriving Eq

-- <expression> ? <expression> : <expression>
data TERNARY = TERNARY EXPRESSION EXPRESSION EXPRESSION deriving Eq
instance Show TERNARY where 
  show (TERNARY x y z) = mconcat [show x, show y, show z]
```

#### Parser

##### A parser szabályok összessége: happyParser.y

Happy-t használtam, ami egy yacc-, vagy bison-szerű megoldás, de haskellben írták, haskell modul fájlt generál a szabályokból, ami közvetlenül felhasználható a projetemben
- Hasonlóan nem fogok mindent leírni, de a legfontosabb szeleteket bemutatom
  - A komment írás happy-ben `%%  %%` jelek között történik
1. rész
   - Első részében, adhatunk meg a kapcsos zárójelek között Haskellben logikát és dependenciákat, amiket szeretnék, hogy használjon a generált fájl.
   - module-ban, ekként a modulként szeretnénk ráhivatkozni
   - Data.Char, néhány segéd művelethez
   - AST, a típusok megadásához.
   - Lexer átadjuk, lexer meghívása utána parser-t megtudjuk hívni

2. rész
- %name -> Itt megadjuk a mi legyen a parser függvény neve, amivel a szabályok által generált függvényt megtudjuk hívni
- %tokentype -> Milyen típusként keresse a tokeneket
- %error -> milyen függvény kezelje le az errort

3. rész
- Itt megadhatók a különböző asszociációk.
- Minél magasabban van, annál kisebb precedenciája.
- nonassoc, az igazából csak placehorder, hogy ha nem akarunk kifejezett asszociációt, de szeretnénk precedenciát.
- `UN` pedig egy azonosító, amit áttudunk adni bizonyos műveleteknek
  - itt azért lett új, mert a `-` már használva lett és így specifikusabban, meg lehet mondani, melyik műveletre melyik asszociáció és precedencia legyen érvényes.



```happy
{
module Generated.HappyParser where

import Data.Char
import AST
import Lexer as L
}

%name parser
%tokentype { Token }
%error { parseError }

%right '='
%nonassoc '?' ':'
%left 'and' 'or'
%left '==' '!='
%left '>' '<' '<=' '>='
%left '+' '-'
%left '*' '/'
%right UN
%nonassoc call
```
4. rész
- Tokenek deklarációja az végtelenül egyszerű
```happy

%token
      NUMBER          { L.NUMBER $$ }
      STRING          { L.STRING $$ }
      IDENTIFIER      { L.IDENTIFIER $$ }
      '='             { L.EQUAL }
      '+'             { L.PLUS }
      '-'             { L.MINUS }
      '*'             { L.STAR }
      %% ... %%
```

5. rész
- Szabályok definiálása
  - Hasonló a BCNF (??) -hez és kiválóan dokumentálja a parser logikáját
  - Amit fontos megjegyezni ebben, hogy a haskelles típusokat itt hozzuk létre, és a `${num}`-mal hivatkozunk arra az elemre, amit használni, akarunk a tokenizált kifejezésekből.
  - `reverse` függvényt gyakran használom, mivel haskell-es listáb mentem el a dolgokat és az akkor hatékony, ha fejére mentünk a listának (egysezeres lista)
    - Lehetett volna szekvenciát használni, de nem láttam akkora előnyét (csak a reverse-t spóroltam volna meg vele.)
```happy
program        : declarations                 { PROG (reverse $1) }

declarations   : declarations declaration     { $2 : $1 }
               | {- empty -}                  { [] }

declaration    : statement                               { DEC_STMT $1 }
               | variable_declaration_assignment ';'     { DEC_VAR $1 }
               | function_declaration                    { DEC_FUNC $1 }
               | class_declaration                       { DEC_CLASS $1 }

statement      : expression_statement              { $1 }
               | print_statement                   { $1 }
               | block_statement                   { $1 }
               | conditional_statement             { $1 }
               | while_statement                   { $1 }
               | for_statement                     { $1 }
               | return_statement                  { $1 }
               | break_statement                   { $1 }
               | continue_statement                { $1 }

expression_statement  : expression ';'                    { EXPR_STMT $1 }
print_statement       : 'print' expression ';'            { PRINT_STMT $2 }
block_statement       : '{' declarations '}'              { BLOCK_STMT (reverse $2) }
conditional_statement : 'if' '(' expression ')' statement                         { IF_STMT $3 $5}
%% ... %%

%% ... %%

variable_declaration_assignment       : variable_declaration                 { $1 }
                                      | variable_assignment                  { $1 }
                                      | class_variable_assignment            { $1 }


variable_declaration                  : 'var' IDENTIFIER '=' expression   { VAR_DEC_DEF $2 $4 }
                                      | 'var' IDENTIFIER                  { VAR_DEC $2 }
variable_assignment                   : IDENTIFIER '=' expression         { VAR_DEF $1 $3 }
class_variable_assignment             : IDENTIFIER '.' IDENTIFIER '=' expression            { CLASS_VAR_DEF $1 $3 $5 }
                                      | 'this' '.' IDENTIFIER '=' expression                { THIS_VAR_DEF $3 $5 }

class_declaration          : 'class' IDENTIFIER '{' methods '}'   { CLASS_DEC $2 (map (DEC_FUNC) (reverse $4)) }
                           | 'class' IDENTIFIER '<' IDENTIFIER '{' methods '}' { SUB_CLASS_DEC $2 $4 (map (DEC_FUNC) (reverse $6)) }
methods                    : {- empty -}                          { [] }
                           | methods method_declaration           { $2 : $1 }

function_declaration       : 'fun' IDENTIFIER '(' parameters ')' block_statement     { FUNC_DEC $2 (reverse $4) $6 }
                           | 'fun' IDENTIFIER '(' ')' block_statement                { FUNC_DEC $2 [] $5 }
method_declaration         : IDENTIFIER '(' parameters ')' block_statement           { METHOD_DEC $1 (reverse $3) $5 }
                           | IDENTIFIER '(' ')' block_statement                      { METHOD_DEC $1 [] $4 }

parameters                 : parameters ',' IDENTIFIER            { (DEC_VAR (PARAM $3)) : $1 }
                           | IDENTIFIER                           { [(DEC_VAR (PARAM $1))] }

%%...%%

expression     : literal        {EXP_LITERAL $1}
               | unary          {EXP_UNARY $1}
               | binary         {EXP_BINARY $1}
               | ternary        {EXP_TERNARY $1}
               | grouping       {EXP_GROUPING $1}
               | function_call  {EXP_CALL $1}
               | chain          {EXP_CHAIN $1}
               | 'this'         {EXP_THIS}

literal        : NUMBER         {AST.NUMBER $1}
               | STRING         {AST.STRING $1}
               | 'true'         {AST.TRUE}
               | 'false'        {AST.FALSE}
               | 'nil'          {AST.NIL}
               | IDENTIFIER     {IDENTIFIER_REFERENCE $1}

grouping       : '(' expression ')'              {GROUP $2}
unary          : '-' expression %prec UN         {UNARY_MINUS $2}
               | '!' expression %prec UN         {UNARY_NEGATE $2}
binary         : expression '==' expression      {BIN_EQ $1 $3}
               | expression '!=' expression      {BIN_NOT_EQ $1 $3}
               | expression '+' expression       {BIN_ADD $1 $3}
               %%...%%

```

6. rész
- Igazából itt hívjuk meg a definiált parseError függvényt, ami le kezelné a hbákat, de sajnos nem jutottam el oda, hogy befejezzem.
- És a függvény ami alapján tudunk, majd hivatkozni a projektemben, erre a logikára, a `happyParser`

```happy
{
parseError :: [Token] -> a
parseError tokens = error ("Parse error" ++ show tokens)


happyParser = parser . lexer

}
```
##### Generálás

- `happy src/HappyParser.y -i -o src/Generated/HappyParser.hs`
- Létrehozza a fájlt, amit a `Runner.hs`-nél behúztunk.
- `-i` kapcsoló pedig létrehozza a `HappyParser.info`-t, amiben leírja, az összes hibát, többértelmű nyelvtant (dangling else), és a szabályok különböző kombinációját (???)


## Rezolver

### Feladata

- Deklarációnál ellenőrizni, hogy már deklarált-e a változó
  - Elsőnél, bárhol, nincs shadowing
  - Másodiknál pedig egy scope-on belül
- Definicíónál ellenőrizni, hogy létezik-e már az a változó, amit definiálni akarunk
- Függvény és Osztály deklarációk lekezelése
- Ciklusok feldolgozása
  - Második megoldásnál, egy közös `LOOP` típus létrehozás a `WHILE` és `FOR` loopokból
- A kulcsszavak ellenőrzése
  - `break` és `continue` cikluson belül
  - `return` függvényen belül
  - `this` osztályon belül
  - `super` gyerekosztályon belül
- Referenciák ellenőrzése
  - Csak már létrehozott változókra legyen referencia
  - Függvényhívások csak függvényeket és osztályokat (inicializálás) hívjanak
- Szülő és gyerek osztály ne használja ugyanazt a nevet
- Osztályoknak van `init` metódus, és a gyerek osztályok ebben meghívják a `super.init()` metódust

#### Új elnevezés
- Indexelt változó: nem függvény vagy osztályon belül deklarált változó
- closure változó: függvényen vagy osztályon belül deklarált változó

### Első Megoldás

#### Alaptípusok

##### AST 
Itt az Parsernél látott AST-t fogjuk használni, itt nem részletezném

##### ResolverMeta

Menjünk végig mi mire való:
- `varIden`: ez egy segéd változó, ami segít abban, hogy feldolgozzuk a következő deklarációkat: `var a = a + 1;`
  - Mivel előbb rekurzív hívásokkal a darabjaira bontjuk, és azon végezzük a feldolgozásokat.
  - `var a`-t előbb felvesszük és hozzáadjuk a ResolverEnvironmenthez (a scope amiben vagyunk)
  - Utána feldolgozzuk az `a+1` kifejezést, mivel felvettük az `a` változót már így kell valami alapján, ami alapján tudjuk, hogy ez még nincs definiálva
  - (Rájöttem, hogy fordítva és lehetett volna hívni, előbb a kifejezést és utána a változó deklarációt. És így felesleges a varIden)
- `rErrors`: Ebben gyűjtjük az az összes resolver által kidobott hibát
- `funcType`: Jelöli milyen függvény típusban vagyunk jelenleg. 
  - Metódusban elfogadott a `this`, `super`, `return`
  - Függvényben csak `return`, más blokkokhoz képest
  - Ha nem vagyunk függvényben, akkor nem fogadjuk el ezen kulcsszavak egyiké sem.
- `resolverEnv`: ez pedig a jelenleg érvényben lévő scope-ok halmaza, ebben tudjuk megtalálni a blokkokon belül mentett indexelt változókat
  - Ennek segítségével nézzük meg, hogy a blokkban mentett változóknál van-e duplikáció, vagy értelmes-e a referecia
  - És az id-t ennek segítségével állítjuk be
- `idenSequence`: Szerintem ez csak benne maradt, majd törlöm
- `newDeclarations`: a feldolgozott deklarációk
  - A stack alján: Globális scope, az összes eddig feldolgozott, mivel amikor végeztünk a feldolgozott blokkok, ide kerülnek
  - A stack tetején: Lokális scope-ban pedig ebben a scope-ban lévő feldolgozott deklarációk
- `newExpressions`: Ebben tárolom ez éppen feldolgozott kifejezéseket
  - Először elmentem a kisebbeket, majd pedig a nagyobbhoz felhasználom ezeket. Kiugrasztom a veremből és összerakom belőle a nagyobbat.
  - Lásd lentebb
- `variableVector`: Ebben gyűjtjük a id-zott változókat, tehát mindent, ami nem függvényen, vagy osztályon belül van.
  - Ebben a verzióban nem engedek meg változó shadowingot, ami egyszerűsített a definíciókat, és elég volt csak az id-kkal dolgozni
- `globalResolverTable`: (Ez is csak benne maradt, mivel mindent, `variableVector`-ban, vagy function scope hashtable-ben tárolunk)
  

```haskell
data ResolverMeta = ResolverMeta {
   varIden :: Maybe T.Text
  , rErrors :: S.Seq ResolverError
  , funcType :: FunctionTypes
  , resolverEnv :: ResolverEnvironment
  , idenSequence :: S.Seq T.Text
  , newDeclarations :: Stack (S.Seq DECLARATION)
  , newExpressions :: Stack EXPRESSION
  , variableVector :: V.Vector EVAL
  , globalResolverTable :: GlobalResolverTable
  } deriving (Show)
  
createResolverMeta :: IO ResolverMeta
createResolverMeta = do
  resEnv <- createNewResEnv
  globTable <- createGlobalResolverTable
  return ResolverMeta {
    varIden=Nothing,
    rErrors=S.empty,
    funcType=NONE,
    resolverEnv=resEnv,
    idenSequence=S.empty,
    newDeclarations= push S.empty createStack,
    newExpressions=createStack,
    variableVector=V.empty,
    globalResolverTable=globTable
    }



data ResolverError = RESOLVER_ERROR T.Text (S.Seq TH.Token) deriving Show

data FunctionTypes = NONE | FUNCTION | METHOD deriving (Show, Eq)

type ResolverBlockEnvironment = HT.BasicHashTable T.Text ID

type ResolverEnvironment = Stack ResolverBlockEnvironment


```

#### Rezolválás logika

- Itt már kicsit több tapasztalattal indultam neki, és látszik, hogy egy jobban olvasható kód lett a végeredmény
- Itt maga a programnak egy feldolgozásának részlete látható.
- Sok helyen `resolve` vagy `resolveExpression` függvény látható, itt kihasználtam a haskell pattern matching funkcionalitását 

##### Blokk rezolválás
- Menjünk egy blokk feldolgozásán
  1. `addBlockToMeta`
     - Az `addNewBlockToResEnv` függvény igazából létrehoz egy hastable-t, amit hozzáadunk a `resEnv`-hez
     - Hozzáadunk egy a `newDeclarations`-höz egy új `Sequence`-t, amiben a eltároljuk majd a feldolgozott deklarációkat
  2. `resolveMulti`: feldolgozza a deklarációkat
  3. `addBlockDecToMeta`: Miután feldolgoztuk a blokkban lévő deklarációkat elmentjük a blokkot, abban a scope-ban, amivel definiáltuk (alatta lévő hashtable-ben a `resEnv`-ben) (!Check! -> Szerintem nem teljesen azt csinálja a függvény, amit eredetileg szerettem volna, check `handleBlockStatementSave`)
     - A `newDeclarations` veremből kipattintjuk a blokkban mentett deklarációkat. 
     - Létrehozzuk a Blokk deklarációt a blokkban mentett deklarációkból
     - Módosítjuk a `newDeclarations` legfelső elemét a létrehozott blokk deklarációval (abban hozták létre)
  4. Töröljük a blokk környzetét a `resEnv`-ből
  
Amit nem kedvelek ebben a megoldásban, az az hogy oda-vissza alakítgatom a deklaráiókat és az állításokat. Ezt külön állításra specializált függvényekkel kellett volna meg oldanom, amit sikerült is a második megoldásban.
     
```haskell
-- Resolver.hs
resolveProgram :: PROGRAM -> IO ResolverMeta
resolveProgram (PROG x) = createResolverMeta >>= resolveMulti x

resolveMulti ::  S.Seq DECLARATION -> ResolverMeta -> IO ResolverMeta
resolveMulti decs meta
  | S.null decs = return meta
  | otherwise =  resolve dec meta >>= resolveMulti (S.drop 1 decs)
  where dec = S.index decs 0

resolve :: DECLARATION -> ResolverMeta -> IO ResolverMeta
resolve (DEC_STMT (BLOCK_STMT decs)) meta = addBlockToMeta meta >>= resolveMulti decs >>= addBlockDecToMeta >>= deleteBlockFromMeta
{-...-}
```

```haskell
-- ResolverTypes.hs
import qualified Data.HashTable.IO as HT

addBlockToMeta :: ResolverMeta -> IO ResolverMeta
addBlockToMeta meta = do
  newEnv <- addNewBlockToResEnv (resolverEnv meta)
  return meta{resolverEnv=newEnv, newDeclarations=(push S.empty (newDeclarations meta))}

addBlockDecToMeta :: ResolverMeta -> IO ResolverMeta
addBlockDecToMeta meta = do
  let (newBlockStmt, last, delDecs) = handleBlockStatementSave meta
  let lastUpdated = last S.|> DEC_STMT newBlockStmt
  return meta{newDeclarations= push lastUpdated delDecs}

deleteBlockFromMeta :: ResolverMeta -> IO ResolverMeta
deleteBlockFromMeta meta = return meta{resolverEnv=(deleteBlockFromResEnv (resolverEnv meta))}


handleBlockStatementSave :: ResolverMeta -> (STATEMENT, S.Seq DECLARATION, Stack (S.Seq DECLARATION))
handleBlockStatementSave meta = (BLOCK_STMT currentBlockDecs, last, delDecs)
  where (currentBlockDecs, delDecs) = pop (newDeclarations meta)
        last = peek delDecs

addNewBlockToResEnv :: ResolverEnvironment -> IO ResolverEnvironment
addNewBlockToResEnv resEnv = do
  block <- createResolverBlockEnvironment
  return (push block resEnv)

deleteBlockFromResEnv :: ResolverEnvironment -> ResolverEnvironment
deleteBlockFromResEnv resEnv = newResEnv
  where (_,newResEnv) = pop resEnv 

createResolverBlockEnvironment :: IO ResolverBlockEnvironment
createResolverBlockEnvironment = HT.new
```


##### Függvény rezolválás
Nézzünk egy függvény definíciót (!check! -> szerintem kell a `deleteBlockFromMeta` a  végéről)
1. `checkHandleIfAlreadyAdded` egy általános függvény, ami megnézi létrehozták-e már a változót, ha igen hibát dob (ebben a verzióban még nem engedtem változó shadowing-ot)
2. elmentjük a régi `funcType` a metáról
3. `handleFunction` felépítése
4. `updateBlockInResEnv` elmentjük a jelenlegi környezetben a változót.
5. `addVariableToVector` elmentjük vektorban a változót
6. `updateFunctionType` frissítjük a `funcType`-ot, függvény típusra, így ha return kulcsszó van a függvényben nem dobunk hibát, (ha rendeltetésszerűen használják).
7. `addBlockToMeta` a függvény törzshöz hozzárendelünk egy resolverEnvironmentet
8. `resolveParams` ezért kellett külön venni és nem csak felhasználtuk a blokk rezolver függvényt
   - így a param feldolgozás a függvény testen belül van, így gyakorlatilag olyan, minthogyha ott lennének deklarálva
   - Az érték adás majd amúgy is az Eval logikában lesz
9. `resolveMulti` feldolgozzuk a függvény testet
10. `addFunctionDecToMeta`, 
    - kiugrasztjuk a függvény által mentett deklarációkat és új függvény deklaráció mentése a felette lévő scope-ba
    - Függvény `resEnv` eltávolítása
    - A régi függvény típus visszaállítása (lehetséges függvény deklarálása függvényen vagy metóduson belül)
- 

```haskell
-- Resolver.hs
{-...-}
resolve  (DEC_FUNC (FUNC_DEC (TH.IDENTIFIER iden) parameters (FUNC_STMT (BLOCK_STMT decs)) (LOCAL_ID id))) meta = checkHandleIfAlreadyAdded handleFunction S.empty iden meta 
  where oldFuncType = funcType meta
        handleFunction meta iden = updateBlockWithFunctionOrClassInMeta (LOCAL_ID id) iden meta >>= printFunc >>= addVariableToVector iden id >>= updateFunctionType FUNCTION >>= addBlockToMeta >>= resolveParams parameters >>= resolveMulti decs >>= addFunctionDecToMeta iden parameters (LOCAL_ID id) oldFuncType
{-...-}

resolveParams :: PARAMETERS -> ResolverMeta -> IO ResolverMeta
resolveParams (PARAMETERS params tokens) meta
  | S.null params = return meta
  | otherwise = checkHandleIfAlreadyAdded (callResolveParams params) tokens iden meta
  where param = S.index params 0
        (DEC_VAR (PARAM_DEC (TH.IDENTIFIER iden) tokens pid)) = param
        callResolveParams params meta iden = updateBlockInMeta pid iden meta >>= cleanVarMeta >>= resolveParams (PARAMETERS (S.drop 1 params) tokens)


```
```haskell
-- ResolverTypes.hs
updateBlockWithFunctionOrClassInMeta :: ID -> T.Text -> ResolverMeta -> IO ResolverMeta
updateBlockWithFunctionOrClassInMeta id iden meta = do
  newEnv <- updateBlockInResEnv iden id (resolverEnv meta)
  return meta{resolverEnv=newEnv}

updateBlockInResEnv :: T.Text -> ID ->  ResolverEnvironment -> IO ResolverEnvironment
updateBlockInResEnv iden id resEnv  = do
  let (last, delResEnv) = pop resEnv 
  HT.insert last iden id
  return (push last delResEnv)

checkHandleIfAlreadyAdded :: (ResolverMeta -> T.Text -> IO ResolverMeta) -> S.Seq TH.Token -> T.Text -> ResolverMeta -> IO ResolverMeta
checkHandleIfAlreadyAdded f tokens iden meta  = do
   res <- checkIfVarAlreadyAdded meta iden
   if res then do
     addError (RESOLVER_ERROR "Variable already added in scope" tokens) meta
   else f meta iden

checkIfVarAlreadyAdded :: ResolverMeta -> T.Text -> IO Bool
checkIfVarAlreadyAdded meta iden = isJust <$> getIdOfIden iden currentBlock
  where currentBlock = peek resEnv
        resEnv = resolverEnv meta

getIdOfIden :: T.Text -> ResolverBlockEnvironment -> IO (Maybe ID)
getIdOfIden iden resEnv = HT.lookup resEnv iden

updateFunctionType :: FunctionTypes -> ResolverMeta -> IO ResolverMeta
updateFunctionType fType meta = return meta{funcType=fType}
```

##### Kifejezés rezolválás
- Ezek jóval egyszeűbb logika alapján mennek, mint az előzőek
- `addSimpleExpression`, hozzáadja a jelenlegi egyszerű kifejezést a veremhez
- Bináris kifejezés:
  - Először a jobboldalt dolgozzuk fel, bekerül a verem aljára, majd pedig a baloldalit, az bekerül a verem tetejére
  - Utána fogjuk az elemeket és kivesszük a veremből és új kifejezést hozunk létre belőle
- Változó referencia:
  - Megnézzük, hogy `var a = a + 1` jellegű kifejezésről van szó, ekkor hibát dobunk
  - Ha pedig még nem deklarálták, akkor azért dobunk hibát
  - Ha ezeken nem dob hibát elmentjük a verembe

```haskell
--Resolver.hs
{-...-}
resolve (DEC_STMT (EXPR_STMT x)) meta = resolveExpression x meta >>= addDecWithExprToMeta (DEC_STMT . EXPR_STMT)
{-...-}

resolveExpression :: EXPRESSION ->  ResolverMeta -> IO ResolverMeta
{-...-}
resolveExpression (EXP_BINARY (BIN left op right) tokens) meta = resolveExpression left meta >>= resolveExpression right >>= addBinaryExpr (op, tokens)
{-...-}
resolveExpression (EXP_LITERAL (IDENTIFIER iden tokens id)) meta = do
  if checkIfResolverError meta iden then do
    addError (RESOLVER_ERROR "Can't read local variable in its own initializer." tokens) meta
  else do
    maybeId <- findIdInVariables iden meta
    if isNothing maybeId then do
      addError (RESOLVER_ERROR "Variable is not declared yet." tokens) meta
    else do
      addSimpleExpr (EXP_LITERAL (IDENTIFIER iden tokens (fromJust maybeId))) meta
{-...-}
resolveExpression expr meta = addSimpleExpr expr meta
```

```haskell
-- ResolverTypes
{-...-}
addError :: ResolverError -> ResolverMeta -> IO ResolverMeta
addError error meta = return meta{rErrors=(rErrors meta S.|> error)}
{-...-}
addDecWithExprToMeta :: (EXPRESSION -> DECLARATION) -> ResolverMeta -> IO ResolverMeta
addDecWithExprToMeta unFinishedDec meta = addDecToMeta (unFinishedDec expr) newMeta
  where (expr, rest) = pop (newExpressions meta)
        newMeta = meta{newExpressions=rest}
{-...-}
checkIfResolverError :: ResolverMeta -> T.Text -> Bool
checkIfResolverError meta iden = Just iden == (varIden meta)
{-...-}
addSimpleExpr :: EXPRESSION -> ResolverMeta -> IO ResolverMeta
addSimpleExpr expr meta = return meta{newExpressions=push expr (newExpressions meta)}
{-...-}
addBinaryExpr :: (OPERATOR, S.Seq TH.Token) -> ResolverMeta -> IO ResolverMeta
addBinaryExpr (op, tokens) meta = return meta{newExpressions=newExprs}
  where (right, fRest) = pop (newExpressions meta)
        (left, sRest) = pop fRest
        newExprs = push (EXP_BINARY (BIN left op right) tokens) sRest
```

### Második megoldás

Fontos különbség az előző megoldáshoz képest, hogy itt végezzük az id osztást a változóknak, nem pedig a parserben

#### Alaptípusok

##### AST
Ezekről volt szó a parsernél.

##### ResolverMeta

Nézzük meg mire valók a változók:
- `resolverEnv`: egy hasító tábla lista, amiben az indexelt változókat tároljuk
  - Egy változó definiálásánal azt nézzük, hogy van-e ugyanolyan nevű a jelenlegi környezetben. Ha hibánk van, akkor nem mentjük az id-jával
  - Egy indexelt változónál felmegyünk a resolver környezetekben, és megkeressük a legközelebbi változót és az lesz az id-ja a referenciának
  - Ez egy megoldás az alábbi hibára: `{var a = 5;} {a = 4;} print a;` Minden blokkra új blokk is készül, és ha rezolváltuk, akkor töröljük, ha csak simán a `variableVector` lenne, akkor az `a` az négy lenne.
  - `currentVariableId`, ez lesz az indexelt változó id-ja, ezt a `variableVector`-ban és a `declarationVector`-ban használjuk
  - `variableVector`, a változókat mentjük el ebben, egy üres `EVAL` típussal, hogy az eval logikában tudjuk majd gyorsan megtalálni az értékeket
  - `declarationVector`, a változók deklarációt mentjük el az id-jukkal együtt, azért, hogy tudjuk ellenőrizni, hogy hívható vagy sem a deklaráció
  - `declarations`, deklarációk listája
  - `resolverErrors`, összes hiba gyűjteménye
  - `newExpr`, ez egy segéd változó, hogy bonyolultabb kifejezéseket feltudjunk dolgozni.
    - hasonló az elgondolás az előzőhöz képest, hasonlóan egy faként tekintek a kifejezésekre, csak itt nem elmentem egy listába, hanem csak magát mentem el, és kiveszem, amikor szükségem van rá, és az újat létrehozom az elmentett értékekből
    - Utólag a korábbi megoldásomat szebbnek ítélem (!check! -> Lehet, hogy át is írom arra, bár ott lehetnek sorrendiségi problémák -> (Nem hogyha sequence-szel van megoldva))
  - `newStmt`
    - Hasonlóan faszerkezetűek a állítások, és hasonló működés mint a kifejezéseknél
  - `isInFunction`, függvény testben vagyunk-e, ha igen, akkor `return` kulcsszót elfogadjuk
  - `isInClass`, osztály testben vagyunk-e, ha igen, akkor a `this` kulcsszót elfogadjuk
  - `isInSubClass`, osztály testben vagyunk-e, ha igen, akkor a `super` kulcsszót elfogadjuk. Csak `isInClass` attribútummal.
  - `isInLoop`, ciklusban vagyunk-e, elfogadjuk-e a `break` és `continue` kulcssazavakat
  - `closure`, closure változók deklarációja, arra való, hogy a deklarációt lmentjük, és tudjuk ellenőrizni, hogy hívható-e a deklaráció, vagy sem.
    - 
```haskell
type ResolverBlockEnvironment = (HT.BasicHashTable T.Text Int)
type ResolverEnvironment = [ResolverBlockEnvironment]
type ResolverClosure = [HT.BasicHashTable TextType DECLARATION]

data ResolverMeta = ResolverMeta {
  -- A list of map to check indexed variables
  --   - for a variable declaration we will check if we have any with the same in the current envieroment -> if we have error, if we don't save it with the id (currentVariableId) 
  --   - for a indexed reference, we will go up the resolver env find the closest variable and use its id to be id of the reference
  -- this is a solution for the following problem {var a = 5;} {a = 4;} print a; -> for every new block a new block env is created , and if a block is resolved, then it is deleted
  resolverEnv :: ResolverEnvironment
  -- This property will be the indexed variable's id, and the variable's index in the variableVector and declarationVector
  , currentVariableId :: Int
  -- An array where we save a new empty eval for an new variable declaration
  -- In the eval, we update them (so a "var a = 4 (ID 4)" is saved in the resolver as a EMPTY_EVAL, but in the evaluation it will updated to "EVAL_NUMBER 4")
  , variableVector :: V.Vector EVAL
  -- An array where we save the new indexed variables' declaration, for checking types (if callable or not) when doing resolution
  , declarationVector :: V.Vector DECLARATION
  -- The current scope's declaration or the global declarations depending what scope are we in.
  , declarations :: [DECLARATION]
  -- All the errors are collected here
  , resolverErrors :: [TextType]
  -- This is a helper for resolving more complex expression 
  -- (expressions are a tree -> from the "root expr" we call the child expr and we save it here, the more complex expr take the resolved, and puts themselves in this property)
  , newExpr :: EXPRESSION
  -- Helper for resolving for complex statement
  -- Statements are trees similar to expression, root stmt calls the child stmt, save it here, the more complex stmt takes the child stmt from here, and puts themselves here
  , newStmt :: STATEMENT
  -- Is in function: helps to check if we need to check the indexed variables or the closure variables, and to check if we call the "return" properly
  -- If true check in closure and returns are valid, if not check in indexed variables and returns are not valid
  , isInFunction :: Bool
    -- Is in function: helps to check if we need to check the indexed variables or the closure variables, and to check if we call the "this" properly
    -- If true check in closure and "this" are valid, if not check in indexed variables and "this" are not valid
  , isInClass :: Bool
  -- Only used with "isInClass", but if this is true "super" is valid
  , isInSubClass :: Bool
  -- To check if "break" and "continue" are valid
  , isInLoop :: Bool
  -- a list of hashtables where we save closure variables, and in the reference resolution checking their types (callable or not)
  , closure :: ResolverClosure
  -- A helper for self recursion.
  -- we don't save the resolved declaration only after we did the body declarations, 
  -- so we save this property and know when it is referenced it should not be looked up, but checked with this
  , currentFunctionName :: TextType
} deriving Show

createNewMeta :: IO ResolverMeta
createNewMeta = do
  resEnv <- createNewResEnv
  return ResolverMeta {
    resolverEnv=resEnv
  , currentVariableId=1
  , variableVector=createGlobalVector
  , declarationVector=createGlobalDeclaration
  , declarations=[]
  , resolverErrors=[]
  , newExpr = EMPTY_EXP
  , newStmt = EMPTY_STMT
  , isInFunction = False
  , isInClass = False
  , isInSubClass = False
  , isInLoop = False
  , closure = []
  , currentFunctionName = ""
  }
 
```

#### Rezolválás logika

Külön logikákat hoztam létre a különböző változatokra

```haskell
resolveProgram :: PROGRAM -> IO ResolverMeta
resolveProgram (PROG decs) = createNewMeta >>= resolveDeclarations decs >>= reverseDeclarationsAndErrors

resolveDeclarations :: [DECLARATION] -> ResolverMeta -> IO ResolverMeta
resolveDeclarations [] meta = return meta
resolveDeclarations (x:xs) meta = resolveDeclaration x meta >>= resolveDeclarations xs

resolveDeclaration :: DECLARATION -> ResolverMeta -> IO ResolverMeta 
resolveDeclaration (DEC_VAR x) meta = resolveVarDeclaration x meta
resolveDeclaration (DEC_CLASS x) meta = resolveClassDeclaration x meta
resolveDeclaration (DEC_STMT stmt) meta = resolveDecStatement stmt meta
resolveDeclaration (DEC_FUNC x) meta = resolveFunctionDeclaration x meta
resolveDeclaration EMPTY_DEC meta = return meta
resolveDeclaration x meta = return meta{declarations=x:declarations meta}
```

##### Blokk rezolválása

- Ebben a megoldásban külön válik a deklaráció és állítás logika, így nem kell odavissza változtatgatni ezeket
- Ezt problémának érzékeltem, az előző megoldásban, és itt javítottam 
Menete:
1. Deklarációk üresre állítása, annak ahol átadjuk azt a `addBlockToMeta`-nak
2. `addBlockToMeta` új környezet hozzáadása a `resEnv`-hez
3. Deklarációk feldolgozása
4. Deklarációk és hibák megfordítása, mivel itt nem szekvenciát használtam, hanem a beépített láncolt listát. (!check! -> valószínű átírom Sequence-re, sokkal kényelmesebb megoldás)
5. Kiszedjük a deklarációkat és elmentjük az elkészült állítást a `newStmt`-be
6. Visszaállítjuk az eredeti `declarations`, kihasználjuk, hogy haskell funkcionális, és closure-ben lévő értéket használjuk
6. Töröljük a blokk környezetét

```haskell
-- Resolver.hs
resolveDecStatement :: STATEMENT -> ResolverMeta -> IO ResolverMeta
resolveDecStatement stmt meta = resolveStatement stmt meta >>= buildDecStmt

 
buildDecStmt :: ResolverMeta -> IO ResolverMeta
buildDecStmt meta = return meta{declarations=DEC_STMT (newStmt meta):declarations meta, newStmt=EMPTY_STMT}
 
{-...-}
 
resolveStatement :: STATEMENT -> ResolverMeta -> IO ResolverMeta
resolveStatement (BLOCK_STMT x) meta = resolveBlock x meta
{-...-}

-- Set the declarations to empty (this is where we will put the resolved block body declarations), 
-- Add block to resEnv, resolve block body, reverse declarations
-- Before returning, deleteBlock from resEnv, add the created block dec to the original declarations
resolveBlock :: [DECLARATION] -> ResolverMeta -> IO ResolverMeta
resolveBlock decs meta = do
  newMeta <- addBlockToMeta meta{declarations=[]} >>= resolveDeclarations decs >>= reverseDeclarationsAndErrors
  deleteBlockFromMeta (newMeta{newStmt=BLOCK_STMT (declarations newMeta), declarations=declarations meta})
{-...-}

```

```haskell
-- ResolverTypes.hs
createResolverBlockEnvironment :: IO ResolverBlockEnvironment
createResolverBlockEnvironment = HT.new

-- Add a new block for the indexed variable checking
addNewBlockToResEnv :: ResolverEnvironment -> IO ResolverEnvironment
addNewBlockToResEnv resEnv = do
  block <- createResolverBlockEnvironment
  return (block:resEnv)

{-...-}

addBlockToMeta :: ResolverMeta -> IO ResolverMeta
addBlockToMeta meta = do
  newEnv <- addNewBlockToResEnv (resolverEnv meta)
  return meta{resolverEnv=newEnv}  

-- This is needed as we save the declarations and errors as a list, and the earliest is the last
reverseDeclarationsAndErrors :: ResolverMeta -> IO ResolverMeta
reverseDeclarationsAndErrors meta = return meta{declarations=reverse (declarations meta), resolverErrors=reverse (resolverErrors meta)} 
```

##### Függvény rezolválása

1. Ellenőrizzük, hogy a változó nevet mentették-e már a scope-ban, ha nem, akkor mentsünk egy üres deklarációt, hogy megkapjuk az id-t
   - És ezt később alakítjuk át a végső verzióra
   - A `checkIfFunctionOrClassIsDefinedAndSaveEmpty` függvényben, a `isInFunctionOrClass` függvénnyel nézzük meg, hogy closure-ben, vagy pedig a indexelt változók között keressük-e az értéket 
2. Elmentjük a `currentFunctionName`, hogy önrekurziónál tudjuk majd használni
3. Hozzáadjuk a környezetét a `resEnv`-hez és a `closure`-t is hozzáadjuk, ahol a deklarációk lesznek elmentve
4. Csekkoljuk a paramétereket, hogy egyedi neveik vannak-e, ha igen hozzáadjuk az hibákhoz `updateResolverErrorsByPredicate` függvény segítségével 
5. Függvény testet rezolváljuk
6. `reserveDeclarationsAndError` fordítás
7. Töröljük a `resEnv`-ből és a `closure`-ből a környezetet
8. Changert meghívjuk: Visszaállítja a `isInFunction` értékét az eredeti értékre, elmenti a rezolválási hibákat, és elmenti a végső függvény deklarációt

```haskell
-- Resolver.hs

-- Check if that identifier is already saved in scope, if not save empty (get id -> will be used for the final dec)
-- Save current function name (for self recursion)
-- Add a new block to resolver environment and a new scope in closure
-- Check if all the params are unique
-- Resolve Function body (is inFunction is set True) and reverse the decs and errors
-- Set current function name to ""
-- Delete block from resEnv, delete scope closure,
-- Call changer, which will set isInFunction to what was originally, saves the resolve errors, creates the final function declaration saves the function declaration to the original declarations
resolveFunctionDeclarationHelper :: TextType -> [DECLARATION] -> [DECLARATION] -> (ID -> TextType -> [DECLARATION] -> ResolverMeta -> ResolverMeta -> IO ResolverMeta) -> ResolverMeta -> IO ResolverMeta
resolveFunctionDeclarationHelper iden params decs changer meta = do
  (id, savedMeta) <- checkIfFunctionOrClassIsDefinedAndSaveEmpty iden meta
  newBlockMeta <- addBlockToMeta savedMeta{currentFunctionName=iden} >>= addClosureToMeta
  let isUniqueParamNames = U.allUnique (map getIdentifierFromParams params)
  updatedParams <- handleParams params newBlockMeta
  newMeta <- resolveDeclarations decs (updateResolverErrorsByPredicate isUniqueParamNames "Parameter names are not unique" (updatedParams{
                                       isInFunction = True
                                       , declarations=[]
  })) >>= reverseDeclarationsAndErrors
  deleteBlockFromMeta newMeta{currentFunctionName=""} >>= deleteClosureFromMeta >>= changer id iden params meta

functionMetaChanger :: ID -> TextType -> [DECLARATION] -> ResolverMeta -> ResolverMeta -> IO ResolverMeta
functionMetaChanger id iden params meta newMeta = updateFunctionOrClassDeclaration id iden dec newMeta{isInFunction = isInFunction meta, resolverErrors=resolverErrors newMeta, declarations=declarations meta}
  where dec = if isInFunction meta then DEC_FUNC (RC_FUNC_DEC iden params (BLOCK_STMT (declarations newMeta))) else DEC_FUNC (R_FUNC_DEC iden params (BLOCK_STMT (declarations newMeta)) id)


```

```haskell
-- ResolverTypes.hs
{-...-}
isInFunctionOrClass :: ResolverMeta -> Bool
isInFunctionOrClass meta = isInFunction meta || isInClass meta
{-...-}
getIdOfIden :: T.Text -> ResolverBlockEnvironment -> IO (Maybe Int)
getIdOfIden iden resEnv = HT.lookup resEnv iden
{-...-}

-- In this function we save the class and function placeholder declaration,
-- Here we check if we already declared a function or a class with this name,
-- And save a dummy declaration.
-- We need to save a dummy declaration, as we don't have the function or class bodies' inner declarations
-- And I thought it was easier to save a dummy, send back the ID and if we have the inner declarations resolved
-- we update the declaration in "updateFunctionOrClassDeclaration"
checkIfFunctionOrClassIsDefinedAndSaveEmpty :: TextType -> ResolverMeta -> IO (ID, ResolverMeta)
checkIfFunctionOrClassIsDefinedAndSaveEmpty iden meta = do
  if isInFunctionOrClass meta then do
    inScope <- isInScope iden meta
    if inScope then do
      return (NON_ID, meta{resolverErrors="Function/class already declared in scope":resolverErrors meta})
    else do
      newMeta <- updateClosureInMeta iden EMPTY_DEC meta 
      return (NON_ID, newMeta)
  else do
    let (currentResEnv:_) = resolverEnv meta
    maybeId <- getIdOfIden iden currentResEnv
    if isNothing maybeId then do
      newMeta <- updateCurrentVariableInMeta iden (const EMPTY_DEC) meta
      return (ID currId, newMeta)
    else
      return (NON_ID, meta{resolverErrors="Function/class already declared in scope":resolverErrors meta})
  where currId = currentVariableId meta

{-...-}
updateResolverErrorsByPredicate :: Bool -> TextType -> ResolverMeta -> ResolverMeta
updateResolverErrorsByPredicate predicate message meta = meta{resolverErrors=if predicate then resolverErrors meta else message:resolverErrors meta}

  
```


