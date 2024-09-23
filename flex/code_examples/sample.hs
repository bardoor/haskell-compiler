data Point = Point { x :: Double,
                     y :: Double
                   } deriving (Eq, Show)

data Vector = Vector { start :: Point,
                       end :: Point
                     } deriving (Eq, Show)


len :: Vector -> Double
len (Vector {start = (Point{x = x1, y = y1}), end = (Point{x = x2, y = y2})}) 
        = sqrt $ (x2 - x1) ** 2 + (y2 - y1) ** 2


projectionX :: Vector -> Double
projectionX (Vector {start = start, end = end}) 
        = x end - x start

projectionY :: Vector -> Double
projectionY (Vector {start = start, end = end}) 
        = y end - y start


-- Сложение
infixl 6 ->+
(->+) :: Vector -> Vector -> Vector
vec1 ->+ vec2 = Vector {start = start vec1, end = Point {x = endX, y = endY}}
        where projX = projectionX vec1 + projectionX vec2
              projY = projectionY vec1 + projectionY vec2
              endX = (x . start $ vec1) + projX
              endY = (y . start $ vec1) + projY


-- Вычитание
infixl 6 ->-
(->-) :: Vector -> Vector -> Vector
vec1 ->- vec2 = Vector {start = start vec1, end = Point {x = endX, y = endY}}
        where projX = projectionX vec1 - projectionX vec2
              projY = projectionY vec1 - projectionY vec2
              endX = (x . start $ vec1) + projX
              endY = (y . start $ vec1) + projY

 
-- Скалярное произведение
infixl 5 ->*
(->*) :: Vector -> Vector -> Double
vec1 ->* vec2 = projX + projY
        where projX = projectionX vec1 * projectionX vec2
              projY = projectionY vec1 * projectionY vec2

