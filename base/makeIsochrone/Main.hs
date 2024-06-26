{-# LANGUAGE TypeApplications #-}
module Main where

import qualified Data.Map as M

import Options.Applicative
import Data.Vector (Vector)
import qualified Data.Vector as V
import qualified Data.Vector.Unboxed as U

import Text.Printf

import Models.Input
import Types
import Types.Internal

import Interpolate


clusterParser :: Parser Cluster
clusterParser = Cluster
                <$> option (maybeReader (Just . MkFeH . packLog . read))
                      (long "cluster-feh"
                       <> metavar "FEH"
                       <> help "Specify cluster FeH")
                <*> option (maybeReader (fmap (MkHeliumFraction . MkPercentage) . closedUnitInterval . read))
                      (long "cluster-y"
                       <> metavar "Y"
                       <> help "Specify cluster Y")
                <*> option (maybeReader (Just . MkLogAge . packLog . read))
                      (long "cluster-age"
                       <> metavar "AGE"
                       <> help "Specify cluster age in log years")

data MakeIsochroneOptions = MakeIsochroneOptions
  { cluster   :: Cluster
  , modelName :: MSModel }

makeIsochroneOptionParser :: Parser MakeIsochroneOptions
makeIsochroneOptionParser = MakeIsochroneOptions <$> clusterParser
                                                 <*> option auto
                                                            (long "model"
                                                             <> metavar "MODEL"
                                                             <> help "Specify model. One of: {OldDsed, NewDsed}")

main :: IO ()
main = do options <- execParser opts
          models  <- convertModels <$> loadModels (modelName $ options)
          let (Isochrone eeps masses magnitudes) = interpolateIsochrone (cluster options) models
              filters = case M.elems magnitudes of
                     (ms:_) -> V.fromList $ map (\i -> concatMap (\v -> printf " %0.6f" (unpackLog . unAbsoluteMagnitude $ v U.! i)) $ M.elems magnitudes) [0.. (U.length ms - 1)]
                     _      -> mempty

          mapM_ (printf "%s ") $ M.keys magnitudes
          putStrLn ""
          V.mapM_ (\(a, b, c) -> printf "%d %0.6f%s\n" a b c) $
            V.zip3 (V.convert eeps)
                   (V.map (unNonNegative . unMass) . V.convert $ masses)
                   (filters :: Vector String)

  where
    opts = info (makeIsochroneOptionParser <**> helper)
      ( fullDesc
     <> progDesc "Generate an isochrone from the models based on cluster parameters")

