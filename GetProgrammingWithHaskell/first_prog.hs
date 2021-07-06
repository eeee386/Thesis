toPart recipient = "Dear " ++ recipient ++ ".\n"

bodyPart bookTitle = "Thanks for buying the " ++ bookTitle ++ ".\n"

fromPart author = "Thanks, " ++ author ++ ".\n"

createEmail recipient bookTitle author = toPart recipient ++
                                         bodyPart bookTitle ++
                                         fromPart author

messyMain :: IO()
messyMain = do
  print "Who is the email for?"
  recipient <- getLine
  print "What is the title?"
  title <- getLine
  print "Who is the author?"
  author <- getLine
  print (createEmail recipient title author)