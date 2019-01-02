module Types exposing (..)

import Mouse exposing (Position)


type alias Reference =
    { conceptId : Int
    , fieldIndex : Int
    , position : Position
    }
