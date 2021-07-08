data AuthorName = AuthorName {
    firstName :: String,
    lastName :: String
}

data Car = Car
data Spoiler = Spoiler
data SportsCar = SportsCar Car Spoiler



type FirstName = String
type LastName = String
type MiddleName = String

data Name = Name FirstName LastName
            | NameWithMiddle FirstName MiddleName LastName
            | TwoInitialsWithLast Char Char LastName
            | FirstNameWithTwoInitials FirstName Char Char deriving Show
data Author = Author Name deriving Show
data Artist = Person Name | Band String deriving Show
data Creator = AuthorCreator Author | ArtistCreator Artist deriving (Show)

hpLovecraft :: Creator
hpLovecraft = AuthorCreator (Author (TwoInitialsWithLast 'H' 'P' "Lovecraft"))

data Book = Book {
    author :: Creator,
    isbn :: String,
    bookTitle :: String,
    bookYear :: Int,
    bookPrice :: Double
}

data VinylRecord = VinylRecord {
    artist :: Creator,
    recordTitle :: String,
    recordYear :: Int,
    recordPrice :: Double
}


data CollectibleToy = CollectibleToy {
    name :: String,
    description :: String,
    toyPrice :: Double
}

data Pamphlets = Pamphlets {
    title :: String,
    pamphletDescription :: String,
    contact :: String
}

data StoreItem = BookItem Book | RecordItem VinylRecord | ToyItem CollectibleToy | PamphletItem Pamphlets

price :: StoreItem -> Double
price (BookItem book) = bookPrice book
price (RecordItem record) = recordPrice record
price (ToyItem toy) = toyPrice toy
price _ = 0

madeBy :: StoreItem -> String
madeBy (BookItem book) = show (author book)
madeBy (RecordItem record) = show (artist record)
madeBy _ = "No creator is assigned to this product"

