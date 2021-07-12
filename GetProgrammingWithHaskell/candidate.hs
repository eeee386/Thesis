import qualified Data.Map as Map

data Grade = F | D | C | B | A deriving (Eq, Ord, Enum, Show, Read)

data Degree = HS | BA | MS | PhD deriving (Eq, Ord, Enum, Show, Read)

data Candidate = Candidate
  { candidateID         :: Int
  , codeReview :: Grade
  , cultureFit :: Grade
  , education  :: Degree
  } deriving (Show)

viable :: Candidate -> Bool 
viable candidate = all (==True) tests
    where passedCoding = codeReview candidate > B
          passedCultureFit = cultureFit candidate > C
          educationMin = education candidate >= MS
          tests = [passedCoding, passedCultureFit, educationMin]

readInt :: IO Int 
readInt = getLine >>= (return . read)

readGrade :: IO Grade
readGrade = getLine >>= (return . read)

readGradeDo :: IO Grade
readGradeDo = do
    gradeStr <- getLine 
    let grade = read gradeStr
    return grade 

readDegree :: IO Degree
readDegree = getLine >>= (return . read)

readCandidate :: IO Candidate
readCandidate = do
  putStr "Id? "
  id <- readInt
  putStr "Code review? "
  codeReview <- readGrade
  putStr "Culture fit? "
  cultureFit <- readGrade
  putStr "Education? "
  education <- readDegree
  return (Candidate id codeReview cultureFit education)


assessCandidateIO :: IO String 
assessCandidateIO = do
    candidate <- readCandidate
    let passed = viable candidate
    let statement = if passed then "passed" else "failed"
    return statement

main :: IO()
main = assessCandidateIO >>= putStrLn 

candidate1 :: Candidate
candidate1 = Candidate 1 A A BA

candidate2 :: Candidate
candidate2 = Candidate 2 C A PhD

candidate3 :: Candidate
candidate3 = Candidate 3 A B MS

candidateDB :: Map.Map Int Candidate
candidateDB = Map.fromList [(1, candidate1), (2, candidate2), (3, candidate3)]

assessCandidateDB :: Int -> Maybe String 
assessCandidateDB cId = do
    candidate <- Map.lookup cId candidateDB
    let passed = viable candidate 
    let statement = if passed then "passed" else "failed"
    return statement

assessCandidateList :: [Candidate] -> [String] 
assessCandidateList candidates = do
    candidate <- candidates
    let passed = viable candidate
    let statement = if passed then "passed" else "failed"
    return statement 

assessCandidate :: Monad m => m Candidate -> m String
assessCandidate candidates = do 
    candidate <- candidates
    let passed = viable candidate
    let statement = if passed then "passed" else "failed"
    return statement

