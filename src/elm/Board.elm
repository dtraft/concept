module Board exposing (..)

import Html exposing (Html)
import Html.Attributes as Html
import Html.Events as Html
import Html.Events.Extra as Html
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Mouse exposing (Position)
import Dict exposing (Dict)
import List.Extra as List


-- Project Modules

import Board.Markers exposing (markers)
import Board.Helpers exposing (maxXPosition, maxYPosition)
import Schemas.Concept as Concept exposing (Concept, FieldType(..), RefType(..), Field, fieldTypeToString, stringToFieldType)
import Types exposing (Reference)


type alias Props msg =
    { onDragMouseDown : Int -> Attribute msg
    , onReferenceMouseDown : Int -> Int -> Attribute msg
    , onReferenceMouseUp : Int -> Attribute msg
    , removeConcept : Int -> msg
    , concepts : Dict Int Concept
    , toConceptMsg : Int -> Concept.Msg -> msg
    , reference : Maybe Reference
    }


type alias Bounds =
    ( Int, Int )


type alias Corners =
    ( Int, Int, Int, Int )


type Orientation
    = Horizontal
    | Vertical


view : Props msg -> Html msg
view props =
    let
        renderedReferences =
            viewReferenceArrows props.concepts

        renderedConcepts =
            props.concepts
                |> Dict.values
                |> List.map (viewConcept props)

        referenceArrow =
            case props.reference of
                Just ref ->
                    viewCreateReferenceArrow props.concepts ref

                Nothing ->
                    []

        minHeight =
            props.concepts
                |> Dict.values
                |> List.foldl maxYPosition 0

        minWidth =
            props.concepts
                |> Dict.values
                |> List.foldl maxXPosition 0
    in
        svg
            [ Html.style
                [ ( "width", (toString minWidth) ++ "px" )
                , ( "height", (toString minHeight) ++ "px" )
                ]
            ]
            (markers
                ++ renderedReferences
                ++ renderedConcepts
                ++ referenceArrow
            )


viewReferenceArrows : Dict Int Concept -> List (Svg msg)
viewReferenceArrows concepts =
    concepts
        |> Dict.values
        |> List.foldr (viewConceptReferenceArrows concepts) []


viewConceptReferenceArrows : Dict Int Concept -> Concept -> List (Svg msg) -> List (Svg msg)
viewConceptReferenceArrows concepts ({ position } as concept) acc =
    concept.fields
        |> List.indexedMap
            (\index field ->
                case field.fieldType of
                    RefField targetId refType ->
                        case Dict.get targetId concepts of
                            Just target ->
                                let
                                    startX =
                                        if target.position.x <= concept.position.x then
                                            concept.position.x
                                        else
                                            concept.position.x + 300

                                    startY =
                                        concept.position.y + 40 + 30 * index + 15

                                    targetRightX =
                                        target.position.x + 300

                                    targetBottomY =
                                        target.fields
                                            |> List.length
                                            |> (*) 30
                                            |> toFloat
                                            |> (+) (toFloat 40 * 2)
                                            |> (+) (toFloat target.position.y)

                                    endMidX =
                                        target.position.x + 150

                                    endMidY =
                                        (targetBottomY - (toFloat target.position.y))
                                            |> (*) 0.5
                                            |> (+) (toFloat target.position.y)

                                    -- Determine all possible targets
                                    endOptions =
                                        [ ( toFloat endMidX, toFloat target.position.y, Vertical )
                                        , ( toFloat targetRightX, endMidY, Horizontal )
                                        , ( toFloat endMidX, targetBottomY, Vertical )
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

                                    -- Get markers
                                    ( startMarker, endMarker ) =
                                        case refType of
                                            OneToOne ->
                                                ( "one", "to-one" )

                                            OneToMany ->
                                                ( "one", "to-many" )

                                            ManyToMany ->
                                                ( "many", "to-many" )
                                in
                                    case Debug.log "min" maybeMin of
                                        Just ( endX, endY, orientation ) ->
                                            let
                                                midX =
                                                    (endX + (toFloat startX)) / 2

                                                midY =
                                                    (endY + (toFloat startY)) / 2

                                                midLines =
                                                    case orientation of
                                                        Vertical ->
                                                            ("L" ++ (toString endX) ++ "," ++ (toString startY))
                                                                ++ (" L" ++ (toString endX) ++ "," ++ (toString endY))

                                                        Horizontal ->
                                                            ("L" ++ (toString midX) ++ "," ++ (toString startY))
                                                                ++ (" L" ++ (toString midX) ++ "," ++ (toString endY))
                                                                ++ (" L" ++ (toString endX) ++ "," ++ (toString endY))

                                                linePath =
                                                    ("M" ++ (toString startX) ++ "," ++ (toString startY))
                                                        ++ (" " ++ midLines)
                                                        ++ (" " ++ "M" ++ (toString endX) ++ "," ++ (toString endY))
                                            in
                                                Svg.path
                                                    [ d linePath
                                                    , class "reference-line"
                                                    , markerStart ("url(#" ++ startMarker ++ ")")
                                                    , markerEnd ("url(#" ++ endMarker ++ ")")
                                                    ]
                                                    []

                                        Nothing ->
                                            text ""

                            Nothing ->
                                text ""

                    _ ->
                        text ""
            )
        |> List.append acc


viewCreateReferenceArrow : Dict Int Concept -> Reference -> List (Svg msg)
viewCreateReferenceArrow concepts { conceptId, fieldIndex, position } =
    case Dict.get conceptId concepts of
        Just concept ->
            let
                ( startX, startY ) =
                    ( concept.position.x + 300 - 12, concept.position.y + 40 + 30 * fieldIndex + 30 - 15 )

                ( endX, endY ) =
                    ( position.x, position.y - 112 )
            in
                [ line
                    [ x1 (toString startX)
                    , y1 (toString startY)
                    , x2 (toString endX)
                    , y2 (toString endY)
                    , class "reference-line"
                    ]
                    []
                ]

        Nothing ->
            []


viewConcept : Props msg -> Concept -> Svg msg
viewConcept { onDragMouseDown, onReferenceMouseDown, onReferenceMouseUp, toConceptMsg, reference, removeConcept } ({ id, position, fields } as concept) =
    let
        conceptMsg =
            toConceptMsg id

        renderedFields =
            fields
                |> List.indexedMap
                    (\i f ->
                        viewField
                            (conceptMsg << (Concept.SetField i))
                            (onReferenceMouseDown id i)
                            (conceptMsg (Concept.RemoveField i))
                            f
                    )
    in
        foreignObject
            [ x (toString position.x)
            , y (toString position.y)
            ]
            [ Html.div
                [ Html.class "concept"
                , Html.style [ ( "width", "300px" ) ]
                , onReferenceMouseUp id
                ]
                [ Html.div
                    [ Html.class "concept--header"
                    , onDragMouseDown id
                    ]
                    [ text concept.name
                    , Html.i
                        [ Html.class "concept--remove ion-close-round"
                        , Html.onClick (removeConcept id)
                        ]
                        []
                    ]
                , Html.div [ Html.class "concept--fields-wrapper" ] renderedFields
                , viewNewField
                    (conceptMsg (Concept.AddField concept.newField))
                    (conceptMsg << Concept.SetNewField)
                    concept.newField
                ]
            ]


viewField : (Field -> msg) -> Attribute msg -> msg -> Field -> Html msg
viewField setField onReferenceStart removeField ({ name, fieldType } as field) =
    let
        renderedFieldType =
            case fieldType of
                RefField conceptId refType ->
                    let
                        baseRef =
                            RefField conceptId

                        button =
                            case refType of
                                OneToOne ->
                                    Html.i
                                        [ Html.class "reference-icon ion-android-checkbox-blank"
                                        , Html.onClick (setField { field | fieldType = baseRef OneToMany })
                                        ]
                                        []

                                OneToMany ->
                                    Html.i
                                        [ Html.class "reference-icon ion-ios-photos"
                                        , Html.onClick (setField { field | fieldType = baseRef ManyToMany })
                                        ]
                                        []

                                ManyToMany ->
                                    Html.i
                                        [ Html.class "reference-icon ion-ios-color-filter"
                                        , Html.onClick (setField { field | fieldType = baseRef OneToOne })
                                        ]
                                        []
                    in
                        Html.div [ Html.class "concept--field--type" ]
                            [ Html.div [] [ text "Reference" ]
                            , button
                            , Html.i
                                [ Html.class "reference-icon ion-close-round"
                                , Html.onClick (setField { field | fieldType = StringField })
                                ]
                                []
                            ]

                _ ->
                    Html.div
                        [ Html.class "concept--field--type-selector" ]
                        [ Html.div
                            [ Html.class "dropdown" ]
                            [ Html.select
                                [ Html.onInput (\t -> setField { field | fieldType = stringToFieldType t }) ]
                                [ Html.option
                                    [ Html.value (fieldTypeToString StringField)
                                    , Html.selected (fieldType == StringField)
                                    ]
                                    [ text "String" ]
                                , Html.option
                                    [ Html.value (fieldTypeToString IntField)
                                    , Html.selected (fieldType == IntField)
                                    ]
                                    [ text "Integer" ]
                                ]
                            ]
                        , Html.i
                            [ onReferenceStart
                            , Html.class "reference-icon ion-android-checkbox-outline-blank"
                            ]
                            []
                        ]
    in
        Html.div
            [ Html.class "concept--field" ]
            [ Html.div
                [ Html.class "concept--field--name" ]
                [ Html.text name
                , Html.i
                    [ Html.class "concept--field--remove ion-close-round"
                    , Html.onClick removeField
                    ]
                    []
                ]
            , renderedFieldType
            ]


viewNewField : msg -> (String -> msg) -> String -> Html msg
viewNewField addField handleInput inputText =
    Html.div [ Html.class "concept--new-field" ]
        [ Html.input
            [ Html.value inputText
            , Html.onInput handleInput
            , Html.onEnter addField
            , Html.placeholder "Add New Field"
            ]
            []
        ]


topRoundedRect : Bounds -> Position -> List (Attribute msg) -> Svg msg
topRoundedRect =
    roundedRect ( 15, 15, 0, 0 )


roundedRect : Corners -> Bounds -> Position -> List (Attribute msg) -> Svg msg
roundedRect ( r1, r2, r3, r4 ) ( width, height ) { x, y } attributes =
    let
        vector_path =
            [ "M" ++ toString (x + r1) ++ "," ++ toString y
            , "h" ++ toString (width - r1 - r2)
            , roundedCorner r2 TopRight
            , "v" ++ toString (height - r2 - r3)
            , roundedCorner r3 BottomRight
            , "h" ++ toString ((width - r3 - r4) * -1)
            , roundedCorner r4 BottomLeft
            , "v" ++ toString ((height - r4 - r1) * -1)
            , roundedCorner r1 TopLeft
            , "Z"
            ]
                |> String.join " "
    in
        Svg.path
            (d vector_path :: attributes)
            []


type Corner
    = TopLeft
    | TopRight
    | BottomRight
    | BottomLeft


roundedCorner : Int -> Corner -> String
roundedCorner r corner =
    let
        rx =
            toString r

        ri =
            toString (r * -1)

        ( r1, r2 ) =
            case corner of
                TopLeft ->
                    ( rx, ri )

                TopRight ->
                    ( rx, rx )

                BottomRight ->
                    ( ri, rx )

                BottomLeft ->
                    ( ri, ri )
    in
        "a" ++ rx ++ "," ++ rx ++ " 0 0 1 " ++ r1 ++ "," ++ r2
