main2 :: IO ()
main2 = putStrLn "Enter a line of text:"
        >> getLine >>= \x -> putStrLn (reverse x)


sequence2 :: (Monad m) => [m a] -> m [a]
sequence2 []     = return []
sequence2 (x:xs) = do
                      v <- x
                      vs <- sequence2 xs
                      return (v:vs)

main4 = forM [1..3] $ \x -> do
          putStr "Looping: "
          print x
