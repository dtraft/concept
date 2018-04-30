module Board.Helpers exposing (..)

import Schemas.Concept as Concept exposing (Concept, Field, FieldType(..), RefType(..))
import Dict exposing (Dict)
import List.Extra as List


-- Types


type Orientation
    = Horizontal
    | Vertical


padding : Int
padding =
    100



-- SVG Helpers


maxYPosition : Concept -> Int -> Int
maxYPosition concept max =
    let
        height =
            concept.position.y + 40 + (List.length concept.fields) * 30 + 40 + padding
    in
        if height > max then
            height
        else
            max


maxXPosition : Concept -> Int -> Int
maxXPosition concept max =
    let
        width =
            concept.position.x + 300 + padding
    in
        if width > max then
            width
        else
            max



-- Reference Arrow Helpers


referenceStartCoordinates : Concept -> Int -> Concept -> ( Int, Int )
referenceStartCoordinates source fieldIndex target =
    let
        x =
            if target.position.x <= source.position.x then
                source.position.x
            else
                source.position.x + 300

        y =
            source.position.y + 40 + 30 * fieldIndex + 15
    in
        ( x, y )


referenceTargetCoordinates : Concept -> ( Int, Int ) -> ( Float, Float, Orientation )
referenceTargetCoordinates target ( startX, startY ) =
    let
        -- Get target bottom corner coordinates
        targetRightX =
            (toFloat target.position.x) + (conceptWidth target)

        targetBottomY =
            (toFloat target.position.y) + (conceptHeight target)

        -- Get target mid points
        endMidX =
            (toFloat target.position.x) + (conceptWidth target / 2)

        endMidY =
            (targetBottomY - (toFloat target.position.y))
                |> (*) 0.5
                |> (+) (toFloat target.position.y)

        -- Determine all possible targets
        endOptions =
            [ ( endMidX, toFloat target.position.y, Vertical )
            , ( targetRightX, endMidY, Horizontal )
            , ( endMidX, targetBottomY, Vertical )
            , ( toFloat target.position.x, endMidY, Horizontal )
            ]

        -- See which one is closest
        maybeMin =
            endOptions
                |> List.minimumBy
                    (\( x, y, _ ) ->
                        ((toFloat startX - x) ^ 2)
                            |> (+) ((toFloat startY - y) ^ 2)
                            |> sqrt
                    )
    in
        maybeMin
            |> Maybe.withDefault ( targetRightX, endMidY, Horizontal )


conceptWidth : Concept -> Float
conceptWidth concept =
    300


conceptHeight : Concept -> Float
conceptHeight concept =
    concept.fields
        |> List.length
        |> (*) 30
        |> toFloat
        |> (+) (toFloat 40 * 2)


getReferenceTarget : Dict Int Concept -> Field -> Maybe ( Concept, RefType )
getReferenceTarget concepts field =
    case field.fieldType of
        RefField targetId refType ->
            case Dict.get targetId concepts of
                Just target ->
                    Just ( target, refType )

                Nothing ->
                    Nothing

        _ ->
            Nothing
