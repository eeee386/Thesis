# Programozási nyelv írása Haskellben

## Bevezetés

## Előszó

Megszeretném köszönni Szabolcs Ivánnak minden segítséget amit nyújtott, ami sokat segített abban, hogy ez a szakdolgozat létrejöjjön.

## Rövid összefoglalás

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

A funckionális programozás alap adatstruktúrája. Egy egyszerű láncolt lista, a legtöbb helyen ezt a adattípust fogom használni a nyelv különböző fázisokban lévő elemeinek tárolására.


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


#### Vektor & Hashmap: a kakukktojások

Ez a két adatstruktúra az, ami nem teljesen funkcionális, de a amit adnak teljesítményben az jobb volt a teljesen funkcionális adatstruktúrák

Vektor: Az hasonlóan működik egy C++-os dinamikus tömbhöz
Hashmap: Az pedig az imperatív leképezés, ennél az adatstruktúránál kellett használni Monádokat

#### Felbukkanó problémák

##### Imperatív vs. Funkcionális

Funkcionális programozásban nincsen állapot kezelés és meg kellett oldanom, hogy valahogyan az állapot az meglegyen a későbbiekre.
- Itt egy meta objektumot használtam, amit a függvényeknek átadtam és abból készítették el az új állapotot. amit használtam.
- 


