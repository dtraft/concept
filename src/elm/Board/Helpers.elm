module Board.Helpers exposing (..)

import Schemas.Concept as Concept exposing (Concept)


padding =
    100


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
