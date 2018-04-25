port module Store exposing (..)

import Json.Encode exposing (Value)


-- port for sending strings out to JavaScript


port save : Value -> Cmd msg


port load : () -> Cmd msg


port loadProject : (Value -> msg) -> Sub msg


port download : Value -> Cmd msg


port loadFile : () -> Cmd msg
