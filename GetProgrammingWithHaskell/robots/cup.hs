-- fl0z is the value, message is the function we will supply later to create quasi-methods, that use the fl0z
cup fl0z message = message fl0z

get0z aCup = aCup (\fl0z -> fl0z)

-- after drinking creates a new object with the new fl0z value
drink aCup ozDrank = if ozDiff > 0 then cup ozDiff else cup 0
    where fl0z = get0z aCup
          ozDiff = fl0z - ozDrank

multipleDrink aCup list = foldl drink aCup list  

isEmpty aCup = get0z aCup == 0 