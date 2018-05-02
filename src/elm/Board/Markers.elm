module Board.Markers exposing (..)

import Svg exposing (..)
import Svg.Attributes exposing (..)


markers : List (Svg msg)
markers =
    let
        axisLength =
            2

        counterAxisLength =
            15

        axisRef =
            (toFloat 10)

        counterAxisRef =
            counterAxisLength / 2

        counterAxisLengthAsString =
            toString counterAxisLength

        startMarkers =
            [ ( "one", "M0,0 V" ++ counterAxisLengthAsString, True, -1, 1 )
            , ( "many", "M0,0 V" ++ counterAxisLengthAsString ++ "M5,0 V" ++ counterAxisLengthAsString, True, -1, 1 )
            , ( "to-one-top", "M0,0 H" ++ counterAxisLengthAsString, False, 1, 1 )
            , ( "to-one-bottom", "M0,0 H" ++ counterAxisLengthAsString, False, 1, -1 )
            , ( "to-one-right", "M0,0 V" ++ counterAxisLengthAsString, True, -1, 1 )
            , ( "to-one-left", "M0,0 V" ++ counterAxisLengthAsString, True, 1, 1 )
            , ( "to-many-top", "M0,0 H" ++ counterAxisLengthAsString ++ " M0,5 H" ++ counterAxisLengthAsString, False, 1, 1 )
            , ( "to-many-bottom", "M0,0 H" ++ counterAxisLengthAsString ++ " M0,5 H" ++ counterAxisLengthAsString, False, 1, -1 )
            , ( "to-many-right", "M0,0 V" ++ counterAxisLengthAsString ++ " M5,0 V" ++ counterAxisLengthAsString, True, -1, 1 )
            , ( "to-many-left", "M0,0 V" ++ counterAxisLengthAsString ++ " M5,0 V" ++ counterAxisLengthAsString, True, 1, 1 )
            ]
    in
        [ defs []
            (startMarkers
                |> List.map
                    (\( htmlId, dPath, isCounterAxis, invertX, invertY ) ->
                        let
                            ( x1, y1 ) =
                                if isCounterAxis then
                                    ( axisRef, counterAxisRef )
                                else
                                    ( counterAxisRef, axisRef )
                        in
                            marker
                                [ id htmlId
                                , orient "auto"
                                , markerWidth (toString counterAxisLength)
                                , markerHeight (toString counterAxisLength)
                                , refX (toString (x1 * invertX))
                                , refY (toString (y1 * invertY))
                                ]
                                [ Svg.path
                                    [ d dPath
                                    , strokeWidth (toString axisLength)
                                    , stroke "black"
                                    , shapeRendering "optimizeSpeed"
                                    ]
                                    []
                                ]
                    )
            )
        ]



--     ,
--     , marker
--         [ id "to-one-bottom"
--         , orient "auto"
--         , markerWidth "15"
--         , markerHeight "2"
--         , refX "7.5"
--         , refY "-10"
--         ]
--         [ Svg.path
--             [ d "M0,0 H15"
--             , strokeWidth "2"
--             , stroke "black"
--             , shapeRendering "optimizeSpeed"
--             ]
--             []
--         ]
--     , marker
--         [ id "to-one-left"
--         , orient "auto"
--         , markerWidth "2"
--         , markerHeight "15"
--         , refX "10"
--         , refY "7.5"
--         ]
--         [ Svg.path
--             [ d "M0,0 V15"
--             , strokeWidth "2"
--             , stroke "black"
--             , shapeRendering "optimizeSpeed"
--             ]
--             []
--         ]
--     , marker
--         [ id "to-one-right"
--         , orient "auto"
--         , markerWidth "2"
--         , markerHeight "15"
--         , refX "-10"
--         , refY "7.5"
--         ]
--         [ Svg.path
--             [ d "M0,0 V15"
--             , strokeWidth "2"
--             , stroke "black"
--             , shapeRendering "optimizeSpeed"
--             ]
--             []
--         ]
--     , marker
--         [ id "many"
--         , orient "auto"
--         , markerWidth "15"
--         , markerHeight "15"
--         , refX "-7.5"
--         , refY "7.5"
--         ]
--         [ Svg.path
--             [ d "M0,0 V15 M5,0 V15"
--             , strokeWidth "2"
--             , stroke "black"
--             , shapeRendering "optimizeSpeed"
--             ]
--             []
--         ]
--     , marker
--         [ id "to-many"
--         , orient "auto"
--         , markerWidth "15"
--         , markerHeight "15"
--         , refX "12.5"
--         , refY "7.5"
--         ]
--         [ Svg.path
--             [ d "M0,0 V15 M5,0 V15"
--             , strokeWidth "2"
--             , stroke "black"
--             , shapeRendering "optimizeSpeed"
--             ]
--             []
--         ]
--     ]
-- ]
