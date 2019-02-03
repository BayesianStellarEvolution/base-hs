module MainSequenceModelSpec (main, spec) where

import Test.Hspec
import Data.Attoparsec.Text (parseOnly)

import MainSequenceModel


main :: IO ()
main = hspec spec

spec = parallel $ do
  describe "MS Model file format" $ do
    describe "Filters" $ do
      let doParse = parseOnly parseFilters

      it "parses a single filter" $
        doParse "%f U\n" == (Right $ Filters ["U"])

      it "parses a list of filters" $
        doParse "%f U B V R I J H K\n" == (Right $ Filters ["U", "B", "V", "R", "I", "J", "H", "K"])


    xdescribe "MS Model section header" $ do
      let doParse = parseOnly parseSectionHeader "%s [Fe/H]=-2.500000    [alpha/Fe]=0.000000    l/Hp=1.938000    Y=0.245100"

      it "parses a section header" $
        let result = doParse
        in result == (Right $ SectionHeader (-2.5) 0.0)


    describe "Comments" $ do
      let desired = Right $ Comment "any text here"
          doParse = parseOnly parseComment

      it "captures a comment with no space after #" $
        doParse "#any text here\n" == desired
      it "skips tabs after #" $
        doParse "# any text here\n" == desired
      it "skips space after #" $
        doParse "#\tany text here\n" == desired


    describe "Header" $ do
      let doParse = parseOnly parseFileHeader

      it "parses a file header" $
        let result = doParse "# DSED models\n%f U B V\n"
        in result == Right [Comment "DSED models", Filters ["U", "B", "V"]]

      it "reads multiple adjacent filter lines as separate lines" $
        let result = doParse "%f U B V\n%f R I J\n"
        in result == Right [Filters ["U", "B", "V"], Filters ["R", "I", "J"]]


    describe "Model" $ do
      let doParse = fmap filters . parseOnly parseModel

      it "parses filters out of the header" $
        let result = doParse "# DSED models\n%f U B V R I J H K u g r i z\n"
        in result == Right ["U","B","V","R","I","J","H","K","u","g","r","i","z"]

      it "concatenates multiple lines of filters" $
        let result = doParse "%f U B V R I J H K\n%f u g r i z\n"
        in result == Right ["U","B","V","R","I","J","H","K","u","g","r","i","z"]
