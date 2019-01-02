module Schemas.Project exposing (Msg(..), Project, decode, decodeConcepts, decodeLoad, decodeResponse, decodeUpdate, empty, encode, test1, update)

-- Elm Libraries
-- Project Libraries

import Dict exposing (Dict)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode
import Schemas.Concept as Concept exposing (Concept, createConcept, createConcept1, createConcept2)



-- Model


type alias Project =
    { id : Maybe String
    , title : String
    , concepts : Dict Int Concept
    }


empty : Project
empty =
    { id = Nothing
    , title = ""
    , concepts = Dict.empty
    }


test1 : Project
test1 =
    let
        project =
            empty

        concept1 =
            createConcept1 "Test 1" 1 ( 100, 100 )

        concept2 =
            createConcept2 "Test 2" 2 ( 300, 300 )
    in
    { project
        | concepts =
            Dict.singleton 1 concept1
                |> Dict.insert 2 concept2
    }



-- Msg


type Msg
    = SetTitle String
    | AddConcept String
    | RemoveConcept Int
    | ConceptMsg Int Concept.Msg
    | SetProject (Result Http.Error Project)



-- Update


update : Msg -> Project -> Project
update msg project =
    case msg of
        SetTitle title ->
            { project | title = title }

        AddConcept name ->
            let
                nextId =
                    project.concepts
                        |> Dict.values
                        |> List.foldl
                            (\c acc ->
                                if c.id > acc then
                                    c.id

                                else
                                    acc
                            )
                            1
                        |> (+) 1

                newConcept =
                    createConcept name nextId

                nextConcepts =
                    Dict.insert nextId newConcept project.concepts
            in
            { project | concepts = nextConcepts }

        RemoveConcept id_ ->
            let
                nextConcepts =
                    Dict.remove id_ project.concepts
            in
            { project | concepts = nextConcepts }

        ConceptMsg id subMsg ->
            let
                nextConcepts =
                    project.concepts
                        |> Dict.update id (Concept.updateInDict subMsg)
            in
            { project | concepts = nextConcepts }

        SetProject result ->
            case result of
                Ok nextProject ->
                    nextProject

                Err error ->
                    project



-- Encoders


encode : Project -> Encode.Value
encode project =
    let
        concepts =
            project.concepts
                |> Dict.toList
                |> List.map (\( id, concept ) -> Concept.encode concept)

        projectId =
            case project.id of
                Just projectId ->
                    Encode.string projectId

                Nothing ->
                    Encode.null

        fields =
            [ ( "id", projectId )
            , ( "data"
              , Encode.object
                    [ ( "name", Encode.string project.title )
                    , ( "concepts", Encode.list concepts )
                    ]
              )
            ]
    in
    Encode.object
        fields



-- Decoders


decode : Decoder Project
decode =
    Decode.decode Project
        |> Decode.required "id" (Decode.nullable Decode.string)
        |> Decode.required "name" Decode.string
        |> Decode.required "concepts" decodeConcepts


decodeLoad : String -> Decoder Project
decodeLoad id_ =
    Decode.decode Project
        |> Decode.hardcoded (Just id_)
        |> Decode.required "name" Decode.string
        |> Decode.required "concepts" decodeConcepts


decodeResponse : Decoder Project
decodeResponse =
    Decode.decode Project
        |> Decode.required "id" (Decode.nullable Decode.string)
        |> Decode.requiredAt [ "data", "name" ] Decode.string
        |> Decode.requiredAt [ "data", "concepts" ] decodeConcepts


decodeUpdate : Decoder Project
decodeUpdate =
    Decode.decode Project
        |> Decode.required "parentId" (Decode.nullable Decode.string)
        |> Decode.requiredAt [ "data", "name" ] Decode.string
        |> Decode.requiredAt [ "data", "concepts" ] decodeConcepts


decodeConcepts : Decoder (Dict Int Concept)
decodeConcepts =
    Decode.list Concept.decode
        |> Decode.map
            (\list ->
                list
                    |> List.map (\c -> ( c.id, c ))
                    |> Dict.fromList
            )
