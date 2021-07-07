data Circle = Circle {
    radius :: Double
} 

data Rectangle = Rectangle {
    a :: Double,
    b :: Double
}

data Square = Square {
    c :: Double
}


data Shape = ShapeCircle Circle | ShapeRectangle Rectangle | ShapeSquare Square

perimeter :: Shape -> Double
perimeter (ShapeCircle circle) = 2*(radius circle)*3.14
perimeter (ShapeRectangle rect) = 2* ((a rect) + (b rect))
perimeter (ShapeSquare squ) = 4*(c squ)

area :: Shape -> Double
area (ShapeCircle circle) = ((radius circle)^2)*3.14
area (ShapeRectangle rect) = (a rect) * (b rect)
area (ShapeSquare squ) = (c squ)*(c squ)