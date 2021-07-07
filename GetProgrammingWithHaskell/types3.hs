data AuthorName = AuthorName {
    firstName :: String,
    lastName :: String
}

data Car = Car
data Spoiler = Spoiler
data SportsCar = SportsCar Car Spoiler



data FirstName = String 
data LastName = String
data MiddleName = String

data Name = Name FirstName LastName 
            | NameWithMiddle FirstName MiddleName LastName 
            | TwoinitialsWithLast Char Char LastName 
            | FirstNameWithTwoInitials FirstName Char Char
data Author = Author Name
data Artist = Person Name | Band String
data Creator = AuthorCreator Author | ArtistCreator Artist deriving Show

hpLovecraft :: Creator
hpLovecraft = AuthorCreator (Author TwoinitialsWithLast 'H' 'P' "Lovecraft")

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

data StoreItem = BookItem Book | RecordItem VinylRecord | ToyItem CollectibleToy | PamphletItem Pamphlet

price :: StoreItem -> Double
price (BookItem book) = bookPrice book
price (RecordItem record) = recordPrice record
price (ToyItem toy) = toyPrice toy 
price _ = 0

madeBy :: StoreItem -> String 
madeBy (BookItem book) = author book
madeBy (RecordItem record) = artist record
madeBy _ = "No creator is assigned to this product"

