module Schemas.Concept exposing (..)

import Mouse exposing (Position)
import List.Extra as List
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Decode


-- Models


type alias Concept =
    { id : Int
    , name : String
    , position : Position
    , fields : List Field
    , newField : String
    , isReordering : Bool
    }


type alias Field =
    { name : String
    , fieldType : FieldType
    }


type FieldType
    = StringField
    | IntField
    | FloatField
    | DecimalField
    | BooleanField
    | DateField
    | TimeField
    | DateTimeField
    | JSONField
    | RefField Int RefType


type RefType
    = OneToOne
    | OneToMany
    | ManyToMany


createConcept : String -> Int -> Concept
createConcept name id =
    { id = id
    , name = name
    , position = Position 100 100
    , fields = []
    , newField = ""
    , isReordering = False
    }


createConcept1 : String -> Int -> ( Int, Int ) -> Concept
createConcept1 name id ( x, y ) =
    { id = id
    , name = name
    , position = Position x y
    , fields =
        [ Field "Test #1" StringField
        , Field "Test #2" (RefField 2 OneToMany)
        , Field "Here is a field with an extremely long name Here is a field with an extremely long name" StringField
        ]
    , newField = ""
    , isReordering = False
    }


createConcept2 : String -> Int -> ( Int, Int ) -> Concept
createConcept2 name id ( x, y ) =
    { id = id
    , name = name
    , position = Position x y
    , fields =
        [ Field "Test #1" StringField
        , Field "Test #2" IntField
        , Field "Test #3" StringField
        ]
    , newField = ""
    , isReordering = False
    }



-- Msgs


type Msg
    = SetNewField String
    | AddField String
    | SetField Int Field
    | SetFieldType Int FieldType
    | RemoveField Int
    | ToggleReorder
    | MoveField Int Int
    | UpdatePosition Float ( Position, Position )



-- Update


updateInDict : Msg -> Maybe Concept -> Maybe Concept
updateInDict msg maybeConcept =
    Maybe.map (update msg) maybeConcept


update : Msg -> Concept -> Concept
update msg concept =
    case msg of
        SetNewField newField ->
            { concept | newField = newField }

        AddField name ->
            let
                fieldType =
                    if name == "id" then
                        IntField
                    else
                        StringField

                nextFields =
                    [ Field name fieldType ]
                        |> List.append concept.fields
            in
                { concept | fields = nextFields, newField = "" }

        SetField index field ->
            let
                nextFields =
                    concept.fields
                        |> List.indexedMap
                            (\i f ->
                                if i == index then
                                    field
                                else
                                    f
                            )
            in
                { concept | fields = nextFields }

        SetFieldType index fieldType ->
            let
                test =
                    Debug.log "index" index

                nextFields =
                    concept.fields
                        |> List.indexedMap
                            (\i f ->
                                if i == index then
                                    { f | fieldType = fieldType }
                                else
                                    f
                            )
            in
                { concept | fields = nextFields }

        RemoveField index ->
            let
                nextFields =
                    concept.fields
                        |> List.removeAt index
            in
                { concept | fields = nextFields }

        ToggleReorder ->
            { concept | isReordering = not concept.isReordering }

        MoveField index offset ->
            { concept | fields = moveItem index offset concept.fields }

        UpdatePosition scale ( start, current ) ->
            let
                position =
                    concept.position

                nextPosition =
                    { x = position.x + round ((toFloat (current.x - start.x)) / scale)
                    , y = position.y + round ((toFloat (current.y - start.y)) / scale)
                    }
            in
                { concept | position = nextPosition }



-- Helpers


moveItem : Int -> Int -> List a -> List a
moveItem fromPos offset list =
    let
        listWithoutMoved =
            List.take fromPos list ++ List.drop (fromPos + 1) list

        moved =
            List.take 1 <| List.drop fromPos list
    in
        List.take (fromPos + offset) listWithoutMoved
            ++ moved
            ++ List.drop (fromPos + offset) listWithoutMoved


fieldTypeToString : FieldType -> String
fieldTypeToString fieldType =
    case fieldType of
        StringField ->
            "string"

        IntField ->
            "int"

        FloatField ->
            "float"

        DecimalField ->
            "decimal"

        BooleanField ->
            "boolean"

        JSONField ->
            "json"

        DateField ->
            "date"

        TimeField ->
            "time"

        DateTimeField ->
            "datetime"

        RefField _ _ ->
            "ref"


refTypeToString : RefType -> String
refTypeToString refType =
    case refType of
        OneToOne ->
            "one-to-one"

        OneToMany ->
            "one-to-many"

        ManyToMany ->
            "many-to-many"


stringToFieldType : String -> FieldType
stringToFieldType input =
    case input of
        "string" ->
            StringField

        "int" ->
            IntField

        "float" ->
            FloatField

        "decimal" ->
            DecimalField

        "boolean" ->
            BooleanField

        "json" ->
            JSONField

        "date" ->
            DateField

        "time" ->
            TimeField

        "datetime" ->
            DateTimeField

        _ ->
            StringField



-- Encoders


encode : Concept -> Encode.Value
encode concept =
    Encode.object
        [ ( "id", Encode.int concept.id )
        , ( "name", Encode.string concept.name )
        , ( "fields", concept.fields |> List.map encodeField |> Encode.list )
        , ( "position", encodePosition concept.position )
        ]


encodePosition : Position -> Encode.Value
encodePosition position =
    Encode.object
        [ ( "pageX", Encode.int position.x )
        , ( "pageY", Encode.int position.y )
        ]


encodeField : Field -> Encode.Value
encodeField field =
    Encode.object
        [ ( "name", Encode.string field.name )
        , ( "fieldType", encodeFieldType field.fieldType )
        ]


encodeFieldType : FieldType -> Encode.Value
encodeFieldType fieldType =
    case fieldType of
        RefField conceptId refType ->
            Encode.object
                [ ( "fieldType", fieldTypeToString fieldType |> Encode.string )
                , ( "conceptId", Encode.int conceptId )
                , ( "refType", refTypeToString refType |> Encode.string )
                ]

        _ ->
            Encode.object
                [ ( "fieldType", fieldTypeToString fieldType |> Encode.string ) ]



-- Decoders


decode : Decoder Concept
decode =
    Decode.decode Concept
        |> Decode.required "id" Decode.int
        |> Decode.required "name" Decode.string
        |> Decode.required "position" Mouse.position
        |> Decode.required "fields" (Decode.list decodeField)
        |> Decode.hardcoded ""
        |> Decode.hardcoded False


decodeField : Decoder Field
decodeField =
    Decode.decode Field
        |> Decode.required "name" Decode.string
        |> Decode.required "fieldType" decodeFieldType


decodeFieldType : Decoder FieldType
decodeFieldType =
    Decode.field "fieldType" Decode.string
        |> Decode.andThen decodeFieldTypeHelper


decodeFieldTypeHelper : String -> Decoder FieldType
decodeFieldTypeHelper fieldType =
    case fieldType of
        "ref" ->
            Decode.map2 RefField
                (Decode.field "conceptId" Decode.int)
                (Decode.field "refType" Decode.string |> Decode.andThen decodeRefTypeHelper)

        strFieldType ->
            Decode.succeed (stringToFieldType strFieldType)


decodeRefTypeHelper : String -> Decoder RefType
decodeRefTypeHelper refType =
    case refType of
        "one-to-one" ->
            Decode.succeed OneToOne

        "one-to-many" ->
            Decode.succeed OneToMany

        "many-to-many" ->
            Decode.succeed ManyToMany

        _ ->
            Decode.fail <|
                "Trying to decode refType, but type "
                    ++ refType
                    ++ " is not supported."
