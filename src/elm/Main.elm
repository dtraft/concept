module Main exposing (Drag, Flags, Model, MouseInteraction(..), Msg(..), Status(..), SubDragMsg(..), SubReferenceMsg(..), dragUpdate, init, initTest, loadProject, main, onDragMouseDown, onReferenceMouseDown, onReferenceMouseUp, referenceUpdate, saveProject, subscriptions, update, view)

-- Local Imports

import Board
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onEnter)
import Http
import Json.Decode as Decode exposing (Decoder, field, int, map, map2, succeed)
import Json.Encode as Encode
import Mouse exposing (Position)
import Schemas.Concept as Concept exposing (Concept)
import Schemas.Project as Project exposing (Project)
import Store
import Types exposing (Reference)



-- APP


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Flags =
    { projectId : String }


type alias Model =
    { project : Project
    , newConceptName : String
    , mouseInteraction : MouseInteraction
    , scale : Float
    , status : Status
    }


type Status
    = Loading
    | Saving
    | Loaded


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( nextCmd, nextStatus ) =
            case flags.projectId of
                "" ->
                    ( Cmd.none, Loaded )

                id_ ->
                    ( loadProject id_, Loading )

        nextModel =
            { project = Project.empty
            , newConceptName = ""
            , mouseInteraction = None
            , scale = 0.8
            , status = nextStatus
            }
    in
    ( nextModel, nextCmd )


initTest : Flags -> ( Model, Cmd Msg )
initTest flags =
    let
        ( model, cmd ) =
            init flags
    in
    ( { model | project = Project.test1 }, cmd )


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
    = SetNewConceptName String
    | CreateNewConcept String
    | DragMsg SubDragMsg
    | ReferenceMsg SubReferenceMsg
    | ProjectMsg Project.Msg
    | SaveProject
    | SaveProjectResponse (Result Http.Error Project)
    | LoadProjectResponse (Result Http.Error Project)
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
        SetNewConceptName name ->
            ( { model | newConceptName = name }, Cmd.none )

        CreateNewConcept name ->
            let
                nextModel =
                    { model | newConceptName = "" }
            in
            update (ProjectMsg (Project.AddConcept name)) nextModel

        ProjectMsg subMsg ->
            let
                nextProject =
                    Project.update subMsg model.project
            in
            ( { model | project = nextProject }, Cmd.none )

        DragMsg subMsg ->
            ( dragUpdate subMsg model, Cmd.none )

        ReferenceMsg subMsg ->
            ( referenceUpdate subMsg model, Cmd.none )

        SaveProject ->
            ( { model | status = Saving }, saveProject model.project )

        SaveProjectResponse result ->
            let
                ( nextModel, nextCmds ) =
                    case result of
                        Ok nextProject ->
                            let
                                nextCmd =
                                    case nextProject.id of
                                        Just id_ ->
                                            Store.setUrl id_

                                        Nothing ->
                                            Cmd.none
                            in
                            ( { model | project = nextProject }, nextCmd )

                        Err error ->
                            let
                                nextError =
                                    Debug.log "Save error: " error
                            in
                            ( model, Cmd.none )
            in
            ( { nextModel | status = Loaded }, nextCmds )

        LoadProjectResponse result ->
            let
                ( nextModel, _ ) =
                    update (SaveProjectResponse result) model
            in
            ( nextModel, Cmd.none )

        DownloadProject ->
            ( model, Store.download (Project.encode model.project) )

        LoadProject ->
            ( model, Store.load () )

        SetLoadedProject value ->
            let
                nextModel =
                    case Decode.decodeValue Project.decode value of
                        Ok nextProject ->
                            { model | project = nextProject }

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
referenceUpdate msg ({ mouseInteraction, project, scale } as model) =
    case msg of
        ReferenceStart reference ->
            let
                position =
                    reference.position

                nextReference =
                    { reference
                        | position =
                            { x = round (toFloat position.x / scale - 1)
                            , y = round (toFloat position.y / scale - 1)
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
                                    { x = round (toFloat (position.x - 1) / scale)
                                    , y = round (toFloat (position.y - 1) / scale - (((1 - scale) * 112) / scale))
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
                                |> Project.ConceptMsg reference.conceptId
                                |> ProjectMsg

                        ( nextModel, cmd ) =
                            update msg model
                    in
                    nextModel

                _ ->
                    model

        ReferenceEnd _ ->
            { model | mouseInteraction = None }


dragUpdate : SubDragMsg -> Model -> Model
dragUpdate msg ({ project } as model) =
    case msg of
        DragStart id xy ->
            let
                nextDrag =
                    Drag xy xy id

                nextMsg =
                    Concept.UpdatePosition model.scale ( nextDrag.start, nextDrag.current )
                        |> Project.ConceptMsg nextDrag.conceptId
                        |> ProjectMsg

                ( nextModel, _ ) =
                    update nextMsg model
            in
            { nextModel | mouseInteraction = DragInteraction nextDrag }

        DragAt xy ->
            case model.mouseInteraction of
                DragInteraction drag ->
                    let
                        nextDrag =
                            { drag | current = xy, start = drag.current }

                        nextMsg =
                            Concept.UpdatePosition model.scale ( nextDrag.start, nextDrag.current )
                                |> Project.ConceptMsg nextDrag.conceptId
                                |> ProjectMsg

                        ( nextModel, _ ) =
                            update nextMsg model
                    in
                    { nextModel | mouseInteraction = DragInteraction nextDrag }

                _ ->
                    model

        DragEnd _ ->
            { model | mouseInteraction = None }



-- HTTP


loadProject : String -> Cmd Msg
loadProject id_ =
    Http.request
        { method = "GET"
        , headers =
            [ Http.header "secret-key" "$2a$10$q.RtK0tIE6qFDm09GfDpw.Ti4ul8DEpQGEaJLeKCe25SwTQjlVwTG"
            ]
        , url = "https://api.jsonbin.io/b/" ++ id_ ++ "/latest"
        , body = Http.emptyBody
        , expect = Http.expectJson (Project.decodeLoad id_)
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send LoadProjectResponse


saveProject : Project -> Cmd Msg
saveProject project =
    let
        body =
            project
                |> Project.encode
                |> Http.jsonBody
    in
    case project.id of
        Just id_ ->
            Http.request
                { method = "PUT"
                , headers =
                    [ Http.header "secret-key" "$2a$10$q.RtK0tIE6qFDm09GfDpw.Ti4ul8DEpQGEaJLeKCe25SwTQjlVwTG"
                    ]
                , url = "https://api.jsonbin.io/b/" ++ id_
                , body = body
                , expect = Http.expectJson Project.decodeUpdate
                , timeout = Nothing
                , withCredentials = False
                }
                |> Http.send SaveProjectResponse

        Nothing ->
            Http.request
                { method = "POST"
                , headers =
                    [ Http.header "secret-key" "$2a$10$q.RtK0tIE6qFDm09GfDpw.Ti4ul8DEpQGEaJLeKCe25SwTQjlVwTG"
                    ]
                , url = "https://api.jsonbin.io/b/"
                , body = body
                , expect = Http.expectJson Project.decodeResponse
                , timeout = Nothing
                , withCredentials = False
                }
                |> Http.send SaveProjectResponse



-- Decode Response
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
                (ProjectMsg << Project.RemoveConcept)
                model.project.concepts
                (\i msg -> ProjectMsg <| Project.ConceptMsg i msg)
                referenceSituation

        saveText =
            if model.status == Saving then
                "Saving..."

            else
                "Save Project"

        loadingText =
            if model.status == Loading then
                "Loading Project..."

            else
                "Enter Project Title"
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
                        , placeholder loadingText
                        , onInput (ProjectMsg << Project.SetTitle)
                        , value model.project.title
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
                                [ li [ onClick SaveProject ] [ text saveText ]
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
                        , onEnter (CreateNewConcept model.newConceptName)
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
                , ( "min-width", toString (100 / model.scale) ++ "%" )
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
        |> Decode.map (ReferenceStart << Reference id fieldIndex)
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
