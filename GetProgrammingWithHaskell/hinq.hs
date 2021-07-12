import Control.Monad
import Control.Applicative

data Name = Name {
    firstName :: String,
    lastName :: String 
}

instance Show Name where 
    show (Name first last) = mconcat [first, " ", last]

data GradeLevel = Freshman | Sophomore | Junior | Senior deriving (Eq, Ord, Enum, Show)

data Student = Student {
    studentId :: Int,
    gardeLevel :: GradeLevel,
    studentName :: Name
} deriving Show

students :: [Student]
students =
  [ Student 1 Senior   (Name "Audre" "Lorde")
  , Student 2 Junior   (Name "Leslie" "Silko")
  , Student 3 Freshman (Name "Judith" "Butler")
  , Student 4 Senior   (Name "Guy" "Debord")
  , Student 5 Sophomore (Name "Jean" "Baudrillard")
  , Student 6 Junior   (Name "Julia" "Kristeva")
  ]

_select :: (Monad m) => (a -> b) -> m a -> m b
_select prop vals = do
    val <- vals
    return (prop val) 

_where :: (Monad m, Alternative m) => (a -> Bool) -> m a -> m a
_where test vals = do
    val <- vals
    guard(test val)
    return val

startsWith :: Char -> String -> Bool
startsWith char string = char == head string


data Teacher = Teacher {
    teacherId :: Int,
    teacherName :: Name
} deriving Show

teachers :: [Teacher]
teachers = [Teacher 100 (Name "Simone" "De Beavoir"), Teacher 200 (Name "Susan" "Sontag")]

data Course = Course {
    courseId :: Int,
    courseTitle :: String,
    teacher :: Int
} deriving Show

courses :: [Course]
courses = [Course 101 "French" 100, Course 201 "English" 200]

_join :: (Monad m, Alternative m, Eq a1) => m a2 -> m t -> (a2 -> a1) -> (t -> a1) -> m (a2, t)
_join data1 data2 prop1 prop2 = do
    d1 <- data1
    d2 <- data2
    let dpairs = (d1, d2)
    guard(prop1 (fst dpairs) == prop2 (snd dpairs))
    return dpairs

_hinq selectQuery joinQuery whereQuery = (\joinData -> (\whereResult -> selectQuery whereResult) (whereQuery joinData)) joinQuery

data HINQ m a b = HINQ (m a -> m b) (m a) (m a -> m a) | HINQ_ (m a -> m b) (m a)

runHINQ :: (Monad m, Alternative m) => HINQ m a b -> m b
runHINQ (HINQ sClause jClause wClause) = _hinq sClause jClause wClause
runHINQ (HINQ_ sClause jClause) = _hinq sClause jClause (_where (\_ -> True))

