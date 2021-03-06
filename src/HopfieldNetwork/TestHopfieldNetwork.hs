import State
import Hopfield
import Util
import Control.Monad.Writer


getHopfield :: LearningRule -> LearningRate -> Int -> [State] -> Writer [String] Hopfield
getHopfield rule rate epochs states =
  let
    s = head states
    indexList = indices s
    initialize' hopfield' = foldr ($) hopfield'
                                  (connect <$> indexList <*> indexList)
    
    learn' :: Hopfield -> [State] -> Writer [String] Hopfield
    learn' hopfield [] = return hopfield
    learn' hopfield (st:sts) = do
      let
        norm = weightNorm 2 hopfield
        newHopfield = learn rule rate (toList st) hopfield
      tell ["Norm of weight: " ++ show norm]
      learn' newHopfield sts
  in
    learn' (initialize' emptyHopfield) (duplicate epochs states)


ordinalAsynUpdate :: Hopfield -> State -> State
ordinalAsynUpdate h s = asynUpdate h (indices s) s


iterate' :: Hopfield -> Int -> State -> Writer [String] State
iterate' h maxStep s
  | maxStep == 0 = return s
  | otherwise = do
    let
      s' = ordinalAsynUpdate h s
      maxStep'
        | s == s' = 0  -- stop iteration.
        | otherwise = maxStep - 1
    tell ["State  | " ++ show s]
    tell ["Energy | " ++ show (energy h s)]
    tell ["------ | --------"]
    iterate' h maxStep' s'


main :: IO ()
main = do
  let
    rate = 0.01
    -- rule = hebbRule
    rule = ojaRule 1
    memory = fromBits
          <$> [ "1010101010101"
              , "0101010101010"
              , "1001001001001" ]
    epochs = 1000
    (hopfield, learnLog) = runWriter $ getHopfield rule rate epochs memory
    maxStep = 5
    -- initState = fromBits "1001001001001"  -- baisc test.
    -- initState = fromBits "1001001011111"
    initState = fromBits "1101001001111"

  putStrLn "\nLearning Process......\n"
  mapM_ putStrLn learnLog

  putStrLn "\nUpdating Process......\n"
  mapM_ putStrLn . snd . runWriter $ iterate' hopfield maxStep initState