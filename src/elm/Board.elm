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
import Board.Helpers exposing (..)
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
                case getReferenceTarget concepts field of
                    Just ( target, refType ) ->
                        let
                            ( startX, startY ) =
                                referenceStartCoordinates concept index target

                            ( endX, endY, orientation ) =
                                referenceTargetCoordinates target ( startX, startY )

                            -- Get markers
                            markers =
                                case refType of
                                    OneToOne ->
                                        ( "one", "to-one" )

                                    OneToMany ->
                                        ( "one", "to-many" )

                                    ManyToMany ->
                                        ( "many", "to-many" )

                            ( startMarker, endMarker ) =
                                markers
                                    |> Tuple.mapSecond (\m -> m ++ "-" ++ orientationToString orientation)
                        in
                            let
                                midX =
                                    (endX + (toFloat startX)) / 2

                                midY =
                                    (endY + (toFloat startY)) / 2

                                midLines =
                                    case getOrientationType orientation of
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
                    ( concept.position.x + (conceptWidth concept) - 12, concept.position.y + 40 + 30 * fieldIndex + 30 - 15 )

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

        boxWidth =
            conceptWidth concept

        renderedFields =
            fields
                |> List.indexedMap
                    (\i f ->
                        viewField
                            (conceptMsg << (Concept.SetField i))
                            (onReferenceMouseDown id i)
                            (conceptMsg (Concept.RemoveField i))
                            (conceptMsg << (Concept.MoveField i))
                            f
                    )
    in
        foreignObject
            [ x (toString position.x)
            , y (toString position.y)
            ]
            [ Html.div
                [ Html.classList
                    [ ( "concept", True )
                    , ( "concept--reordering", concept.isReordering )
                    ]
                , Html.style [ ( "width", toString boxWidth ++ "px" ) ]
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
                    , Html.i
                        [ Html.classList
                            [ ( "concept--reorder", True )
                            , ( "ion-arrow-swap", not concept.isReordering )
                            , ( "ion-checkmark-round", concept.isReordering )
                            ]
                        , Html.onClick (conceptMsg Concept.ToggleReorder)
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


viewField : (Field -> msg) -> Attribute msg -> msg -> (Int -> msg) -> Field -> Html msg
viewField setField onReferenceStart removeField moveField ({ name, fieldType } as field) =
    let
        renderedFieldType =
            case fieldType of
                RefField conceptId refType ->
                    let
                        baseRef =
                            RefField conceptId

                        ( rotateRefType, label ) =
                            case refType of
                                OneToOne ->
                                    ( setField { field | fieldType = baseRef OneToMany }, "One-to-one" )

                                OneToMany ->
                                    ( setField { field | fieldType = baseRef ManyToMany }, "One-to-many" )

                                ManyToMany ->
                                    ( setField { field | fieldType = baseRef OneToOne }, "Many-to-many" )
                    in
                        Html.div [ Html.class "concept--field--type" ]
                            [ Html.div
                                [ Html.onClick rotateRefType
                                , Html.class "pointer"
                                ]
                                [ text label ]
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
                                    [ Html.value (fieldTypeToString BooleanField)
                                    , Html.selected (fieldType == BooleanField)
                                    ]
                                    [ text "Boolean" ]
                                , Html.option
                                    [ Html.value (fieldTypeToString IntField)
                                    , Html.selected (fieldType == IntField)
                                    ]
                                    [ text "Integer" ]
                                , Html.option
                                    [ Html.value (fieldTypeToString FloatField)
                                    , Html.selected (fieldType == FloatField)
                                    ]
                                    [ text "Float" ]
                                , Html.option
                                    [ Html.value (fieldTypeToString DecimalField)
                                    , Html.selected (fieldType == DecimalField)
                                    ]
                                    [ text "Decimal" ]
                                , Html.option
                                    [ Html.value (fieldTypeToString JSONField)
                                    , Html.selected (fieldType == JSONField)
                                    ]
                                    [ text "JSON" ]
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
                [ Html.span [] [ Html.text name ]
                , Html.i
                    [ Html.class "concept--field--remove ion-close-round"
                    , Html.onClick removeField
                    ]
                    []
                , Html.div
                    [ Html.class "concept--field--reorder-icons"
                    ]
                    [ Html.i
                        [ Html.class "concept--field--reorder-icon ion-chevron-up"
                        , Html.onClick (moveField -1)
                        ]
                        []
                    , Html.i
                        [ Html.class "concept--field--reorder-icon ion-chevron-down"
                        , Html.onClick (moveField 1)
                        ]
                        []
                    ]
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
