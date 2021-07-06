half :: Int -> Double 
half n = (fromIntegral n)/2

halve :: Int -> Int 
halve n = n `div` 2

printDouble :: Int -> String 
printDouble n = show (n*2)

anotherNumber :: Int 
anotherNumber = read "6"

simple :: a -> a
simple n = n


makeTriplet :: a -> b -> c -> (a,b,c)
makeTriplet x y z = (x,y,z)

myTail :: [a] -> [a]
myTail [] = []
myTail (x:xs) = xs


type PatientName = (String, String)
type Age = Int
type Height = Int

type PatientInfo = PatientName -> Age -> Height

firstName :: PatientName -> String 
firstName name = fst name

lastName :: PatientName -> String 
lastName name = snd name

data Sex = Male | Female | Other

sexInitial :: Sex -> Char
sexInitial Male = 'M'
sexInitial Female = 'F'
sexInitial Other = 'O' 

data RhType = Pos | Neg
data ABOType = A | B | AB | O

data BloodType = BloodType ABOType RhType

showRh :: RhType -> String 
showRh Pos = "+"
showRh Neg = "-"
showABO :: ABOType -> String 
showABO A = "A"
showABO B = "B"
showABO AB = "AB"
showABO O = "O"

showBloodType :: BloodType -> String 
showBloodType (BloodType abo rh) = showABO abo ++ showRh rh 

canDonateTo :: BloodType -> BloodType -> Bool 
canDonateTo (BloodType O _) _ = True 
canDonateTo _ (BloodType AB _) = True 
canDonateTo (BloodType A _) (BloodType A _) = True
canDonateTo (BloodType B _) (BloodType B _) = True 
canDonateTo _ _ = False


type MiddleName = String
type FirstName = String
type LastName = String
data Name = Name FirstName LastName | NameWithMiddle FirstName MiddleName LastName


data Patient = Patient {
    name :: Name,
    sex :: Sex,
    age :: Int,
    height :: Int,
    weight :: Int,
    bloodType :: BloodType 
}

canDonateToPatient :: Patient -> Patient -> Bool 
canDonateToPatient p1 p2 = canDonateTo (bloodType p1) (bloodType p2)

