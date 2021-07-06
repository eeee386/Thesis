robot (name, attack, hp) message = message (name, attack, hp)

name (n, _, _) = n
attack (_, a, _) = a
hp(_, _, hp) = hp

getName aRobot = aRobot name
getAttack aRobot = aRobot attack
getHp aRobot = aRobot hp

setName aRobot newName = aRobot (\(_,a,h) -> robot (newName, a, h))
setAttack aRobot newAttack = aRobot (\(n,_,h) -> robot (n, newAttack, h))
setHp aRobot newHp = aRobot (\(n, a, _) -> robot (n, a, newHp))

printRobot aRobot = aRobot (\(n,a,h) -> n ++ ", attack: " ++ a ++ ", hp: " ++ h)

damage aRobot attackDamage = aRobot (\(n, a, h) -> robot (n, a, h-attackDamage))

fight aRobot defender = damage defender attack  
    where attack = if getHp aRobot > 0 then getAttack aRobot else 0

getLifeOfRobotsFromAList listOfRobots = map getHp listOfRobots

{--threeRoundFight robotA robotB =
    let 
        round = 6
        roundsOfFight robotA robotB counter 
            | getHp robotA <= 0 = "Winner is " ++ getName robotB
            | getHp robotB <= 0 = "Winner is " ++ getName robotA
            | counter == 0 = "Draw"
            | even counter = roundsOfFight robotA (fight robotA robotB) (counter-1)
            | odd counter = roundsOfFight (fight robotB robotA) robotB (counter-1)
    in
        roundsOfFight robotA robotB round--}

fightMultipleRobots aRobot listOfRobots = map (fight aRobot) listOfRobots
