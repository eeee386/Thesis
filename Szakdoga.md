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
- Csak betűkből állhat a változó név
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


