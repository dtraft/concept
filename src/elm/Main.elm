module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onEnter)
import Dict exposing (Dict)
import Json.Decode exposing (succeed, Decoder, map, map2, field, int)
import Mouse exposing (Position)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode


-- Local Imports

import Types exposing (Reference)
import Schemas.Concept as Concept exposing (Concept, createConcept, createConcept2)
import Board
import Store


-- APP


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { projectTitle : String
    , newConceptName : String
    , concepts : Dict Int Concept
    , mouseInteraction : MouseInteraction
    , scale : Float
    }


init : ( Model, Cmd Msg )
init =
    let
        nextModel =
            { projectTitle = ""
            , newConceptName = ""
            , concepts = Dict.empty
            , mouseInteraction = None
            , scale = 0.8
            }
    in
        ( nextModel, Cmd.none )


initTest : ( Model, Cmd Msg )
initTest =
    let
        ( model, cmd ) =
            init
    in
        ( { model
            | concepts =
                Dict.singleton 1 (createConcept2 "Test 1" 1 ( 100, 100 ))
                    |> Dict.insert 2 (createConcept2 "Test 2" 2 ( 700, 100 ))
            , scale = 1
          }
        , cmd
        )


type MouseInteraction
    = None
    | DragInteraction Drag
    | ReferenceInteraction Reference


type alias Drag =
    { start : Position
    , current : Position
    , conceptId : Int
    }



-- UPDATE


type Msg
    = SetTitle String
    | SetNewConceptName String
    | AddConcept String
    | RemoveConcept Int
    | DragMsg SubDragMsg
    | ReferenceMsg SubReferenceMsg
    | ConceptMsg Int Concept.Msg
    | SaveProject
    | DownloadProject
    | LoadProject
    | SetLoadedProject Encode.Value
    | LoadFile
    | ScaleUp
    | ScaleDown


type SubDragMsg
    = DragStart Int Position
    | DragAt Position
    | DragEnd Position


type SubReferenceMsg
    = ReferenceStart Reference
    | MouseAt Position
    | CreateReference Int
    | ReferenceEnd Position


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetTitle title ->
            ( { model | projectTitle = title }, Cmd.none )

        SetNewConceptName name ->
            ( { model | newConceptName = name }, Cmd.none )

        AddConcept name ->
            let
                nextId =
                    model.concepts
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
                    Dict.insert nextId newConcept model.concepts
            in
                ( { model | concepts = nextConcepts, newConceptName = "" }, Cmd.none )

        RemoveConcept id ->
            let
                nextConcepts =
                    Dict.remove id model.concepts
            in
                ( { model | concepts = nextConcepts }, Cmd.none )

        ConceptMsg id subMsg ->
            let
                nextConcepts =
                    model.concepts
                        |> Dict.update id (Concept.updateInDict subMsg)
            in
                ( { model | concepts = nextConcepts }, Cmd.none )

        DragMsg subMsg ->
            ( (dragUpdate subMsg model), Cmd.none )

        ReferenceMsg subMsg ->
            ( (referenceUpdate subMsg model), Cmd.none )

        SaveProject ->
            ( model, Store.save (encodeProject model) )

        DownloadProject ->
            ( model, Store.download (encodeProject model) )

        LoadProject ->
            ( model, Store.load () )

        SetLoadedProject value ->
            let
                nextModel =
                    case Decode.decodeValue decodeModel value of
                        Ok model ->
                            model

                        Err error ->
                            let
                                test =
                                    Debug.log "error: " error
                            in
                                model
            in
                ( nextModel, Cmd.none )

        LoadFile ->
            ( model, Store.loadFile () )

        ScaleUp ->
            let
                nextScale =
                    if model.scale < 1 then
                        model.scale + 0.1
                    else
                        model.scale
            in
                ( { model | scale = nextScale }, Cmd.none )

        ScaleDown ->
            let
                nextScale =
                    if model.scale > 0.5 then
                        model.scale - 0.1
                    else
                        model.scale
            in
                ( { model | scale = nextScale }, Cmd.none )


referenceUpdate : SubReferenceMsg -> Model -> Model
referenceUpdate msg ({ mouseInteraction, concepts, scale } as model) =
    case msg of
        ReferenceStart reference ->
            let
                position =
                    reference.position

                nextReference =
                    { reference
                        | position =
                            { x = round ((toFloat position.x) / scale - 1)
                            , y = round ((toFloat position.y) / scale - 1)
                            }
                    }
            in
                { model | mouseInteraction = ReferenceInteraction nextReference }

        MouseAt position ->
            case mouseInteraction of
                ReferenceInteraction reference ->
                    let
                        nextReference =
                            { reference
                                | position =
                                    { x = round ((toFloat (position.x - 1)) / scale)
                                    , y = round ((toFloat (position.y - 1)) / scale - (((1 - scale) * 112) / scale))
                                    }
                            }
                    in
                        { model | mouseInteraction = ReferenceInteraction nextReference }

                _ ->
                    model

        CreateReference targetId ->
            case mouseInteraction of
                ReferenceInteraction reference ->
                    let
                        msg =
                            Concept.SetFieldType reference.fieldIndex (Concept.RefField targetId Concept.OneToOne)
                                |> ConceptMsg reference.conceptId

                        ( nextModel, cmd ) =
                            update msg model
                    in
                        nextModel

                _ ->
                    model

        ReferenceEnd _ ->
            { model | mouseInteraction = None }


dragUpdate : SubDragMsg -> Model -> Model
dragUpdate msg ({ concepts } as model) =
    case msg of
        DragStart id xy ->
            let
                nextDrag =
                    Drag xy xy id

                nextConcepts =
                    concepts
                        |> Dict.update nextDrag.conceptId (updateConceptPosition model.scale nextDrag)
            in
                { model | mouseInteraction = DragInteraction nextDrag, concepts = nextConcepts }

        DragAt xy ->
            case model.mouseInteraction of
                DragInteraction drag ->
                    let
                        nextDrag =
                            { drag | current = xy, start = drag.current }

                        nextConcepts =
                            concepts
                                |> Dict.update nextDrag.conceptId (updateConceptPosition model.scale nextDrag)
                    in
                        { model | mouseInteraction = DragInteraction nextDrag, concepts = nextConcepts }

                _ ->
                    model

        DragEnd _ ->
            { model | mouseInteraction = None }


updateConceptPosition : Float -> Drag -> Maybe Concept -> Maybe Concept
updateConceptPosition scale { start, current } maybeConcept =
    case maybeConcept of
        Just ({ position } as concept) ->
            let
                nextPosition =
                    { x = position.x + round ((toFloat (current.x - start.x)) / scale)
                    , y = position.y + round ((toFloat (current.y - start.y)) / scale)
                    }
            in
                Just { concept | position = nextPosition }

        Nothing ->
            Nothing



-- VIEW
-- Html is defined as: elem [ attribs ][ children ]
-- CSS can be applied via class names or inline style attrib


view : Model -> Html Msg
view model =
    let
        referenceSituation =
            case model.mouseInteraction of
                ReferenceInteraction reference ->
                    Just reference

                _ ->
                    Nothing

        boardProps =
            Board.Props
                onDragMouseDown
                onReferenceMouseDown
                onReferenceMouseUp
                RemoveConcept
                model.concepts
                ConceptMsg
                referenceSituation
    in
        div [ class "app-wrapper" ]
            [ div [ class "header" ]
                [ div [ class "header--left" ]
                    [ h1
                        []
                        [ text "Concept" ]
                    , div
                        [ class "header--title" ]
                        [ input
                            [ id "project-title"
                            , placeholder "Enter Project Title"
                            , onInput SetTitle
                            , value model.projectTitle
                            ]
                            []
                        ]
                    ]
                , div [ class "header--right" ]
                    [ div [ class "header--utility" ]
                        [ button [ class "btn icon-btn ion-plus-round", type_ "button", onClick ScaleUp ]
                            []
                        , button [ class "btn icon-btn ion-minus-round", type_ "button", onClick ScaleDown ]
                            []
                        , div [ class "header--utility--menu" ]
                            [ button [ class "btn icon-btn ion-navicon-round", type_ "button" ]
                                []
                            , div [ class "header--utility--menu--list--wrapper" ]
                                [ ul [ class "header--utility--menu--list" ]
                                    [ li [ onClick SaveProject ] [ text "Save Project" ]
                                    , li [ onClick LoadProject ] [ text "Load Project" ]
                                    , li [ onClick DownloadProject ] [ text "Download" ]
                                    , li [ class "file-input" ]
                                        [ input
                                            [ type_ "file"
                                            , multiple False
                                            , id "load-file"
                                            , accept ".concept"
                                            , on "change" (Decode.succeed LoadFile)
                                            ]
                                            []
                                        , text "Load from File"
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    , div [ class "header--add-concept" ]
                        [ input
                            [ class "form-control"
                            , id "new-concept"
                            , placeholder "Add new concept"
                            , onInput SetNewConceptName
                            , value model.newConceptName
                            , onEnter (AddConcept model.newConceptName)
                            ]
                            []
                        ]
                    ]
                ]
            , div
                [ classList
                    [ ( "board", True )
                    , ( "create-reference", referenceSituation /= Nothing )
                    ]
                , style
                    [ ( "transform", "scale(" ++ toString model.scale ++ ")" )
                    , ( "transform-origin", "0 0" )
                    , ( "min-width", (toString (100 / model.scale)) ++ "%" )
                    , ( "min-height", "calc(" ++ toString (100 / model.scale) ++ "% - 112px)" )
                    ]
                ]
                [ Board.view boardProps ]
            ]


onDragMouseDown : Int -> Attribute Msg
onDragMouseDown id =
    Mouse.position
        |> Decode.map (DragStart id)
        |> Decode.map DragMsg
        |> on "mousedown"


onReferenceMouseDown : Int -> Int -> Attribute Msg
onReferenceMouseDown id fieldIndex =
    Mouse.position
        |> Decode.map (ReferenceStart << (Reference id fieldIndex))
        |> Decode.map ReferenceMsg
        |> on "mousedown"


onReferenceMouseUp : Int -> Attribute Msg
onReferenceMouseUp id =
    CreateReference id
        |> ReferenceMsg
        |> Decode.succeed
        |> on "mouseup"



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        mouseSubs =
            case model.mouseInteraction of
                None ->
                    []

                DragInteraction _ ->
                    [ Mouse.moves DragAt, Mouse.ups DragEnd ]
                        |> List.map (Sub.map DragMsg)

                ReferenceInteraction _ ->
                    [ Mouse.moves MouseAt, Mouse.ups ReferenceEnd ]
                        |> List.map (Sub.map ReferenceMsg)
    in
        Store.loadProject SetLoadedProject
            :: mouseSubs
            |> Sub.batch



-- Encoders


encodeProject : Model -> Encode.Value
encodeProject model =
    let
        concepts =
            model.concepts
                |> Dict.toList
                |> List.map (\( id, concept ) -> Concept.encode concept)
    in
        Encode.object
            [ ( "name", Encode.string model.projectTitle )
            , ( "concepts", Encode.list concepts )
            ]



-- Decoders


decodeModel : Decoder Model
decodeModel =
    Decode.decode Model
        |> Decode.required "name" Decode.string
        |> Decode.hardcoded ""
        |> Decode.required "concepts" decodeConcepts
        |> Decode.hardcoded None
        |> Decode.hardcoded 1


decodeConcepts : Decoder (Dict Int Concept)
decodeConcepts =
    Decode.list Concept.decode
        |> Decode.map
            (\list ->
                list
                    |> List.map (\c -> ( c.id, c ))
                    |> Dict.fromList
            )
