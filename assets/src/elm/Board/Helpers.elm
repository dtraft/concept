module Board.Helpers exposing (..)

import Schemas.Concept as Concept exposing (Concept, Field, FieldType(..), RefType(..))
import Dict exposing (Dict)
import List.Extra as List


-- Types


type Orientation
    = Top
    | Bottom
    | Left
    | Right


type OrientationType
    = Vertical
    | Horizontal


padding : Int
padding =
    100


orientationToString : Orientation -> String
orientationToString orientation =
    case orientation of
        Top ->
            "top"

        Bottom ->
            "bottom"

        Left ->
            "left"

        Right ->
            "right"


getOrientationType : Orientation -> OrientationType
getOrientationType orientation =
    case orientation of
        Top ->
            Vertical

        Bottom ->
            Vertical

        Left ->
            Horizontal

        Right ->
            Horizontal



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
            concept.position.x + (conceptWidth concept) + padding
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
                source.position.x + conceptWidth source

        y =
            source.position.y + 40 + 30 * fieldIndex + 15
    in
        ( x, y )


referenceTargetCoordinates : Concept -> ( Int, Int ) -> ( Float, Float, Orientation )
referenceTargetCoordinates target ( startX, startY ) =
    let
        -- Get target bottom corner coordinates
        targetRightX =
            target.position.x
                + (conceptWidth target)
                |> toFloat

        targetBottomY =
            (toFloat target.position.y) + (conceptHeight target)

        -- Get target mid points
        endMidX =
            (toFloat target.position.x) + (toFloat (conceptWidth target) / 2)

        endMidY =
            (targetBottomY - (toFloat target.position.y))
                |> (*) 0.5
                |> (+) (toFloat target.position.y)

        positionY =
            toFloat target.position.y

        positionX =
            toFloat target.position.x

        -- Determine all possible targets
        endOptions =
            [ ( endMidX, positionY, Vertical )
            , ( targetRightX, endMidY, Horizontal )
            , ( endMidX, targetBottomY, Vertical )
            , ( positionX, endMidY, Horizontal )
            ]
                |> List.map
                    (\( x, y, orientationType ) ->
                        let
                            orientation =
                                case orientationType of
                                    Vertical ->
                                        if (toFloat startY) >= y then
                                            Bottom
                                        else
                                            Top

                                    Horizontal ->
                                        if (toFloat startX) >= x then
                                            Right
                                        else
                                            Left
                        in
                            ( x, y, orientation )
                    )

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
            |> Maybe.withDefault ( targetRightX, endMidY, Left )


conceptWidth : Concept -> Int
conceptWidth concept =
    concept.fields
        |> List.map (\f -> String.length f.name)
        |> List.maximum
        |> Maybe.withDefault 0
        |> (*) 7
        |> (+) 175
        |> clamp 300 500


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
