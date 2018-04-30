module Board.Markers exposing (..)

import Svg exposing (..)
import Svg.Attributes exposing (..)


markers : List (Svg msg)
markers =
    [ defs []
        [ marker
            [ id "one"
            , orient "auto"
            , markerWidth "2"
            , markerHeight "15"
            , refX "-7.5"
            , refY "7.5"
            ]
            [ Svg.path
                [ d "M0,0 V15"
                , strokeWidth "2"
                , stroke "black"
                , shapeRendering "optimizeSpeed"
                ]
                []
            ]
        , marker
            [ id "to-one-horizontal"
            , orient "auto"
            , markerWidth "2"
            , markerHeight "15"
            , refX "7.5"
            , refY "7.5"
            ]
            [ Svg.path
                [ d "M0,0 V15"
                , strokeWidth "2"
                , stroke "black"
                , shapeRendering "optimizeSpeed"
                ]
                []
            ]
        , marker
            [ id "to-one-top"
            , orient "auto"
            , markerWidth "15"
            , markerHeight "2"
            , refX "7.5"
            , refY "7.5"
            ]
            [ Svg.path
                [ d "M0,0 H15"
                , strokeWidth "2"
                , stroke "black"
                , shapeRendering "optimizeSpeed"
                ]
                []
            ]
        , marker
            [ id "to-one-bottom"
            , orient "auto"
            , markerWidth "15"
            , markerHeight "2"
            , refX "7.5"
            , refY "-7.5"
            ]
            [ Svg.path
                [ d "M0,0 H15"
                , strokeWidth "2"
                , stroke "black"
                , shapeRendering "optimizeSpeed"
                ]
                []
            ]
        , marker
            [ id "many"
            , orient "auto"
            , markerWidth "15"
            , markerHeight "15"
            , refX "-7.5"
            , refY "7.5"
            ]
            [ Svg.path
                [ d "M0,0 V15 M5,0 V15"
                , strokeWidth "2"
                , stroke "black"
                , shapeRendering "optimizeSpeed"
                ]
                []
            ]
        , marker
            [ id "to-many"
            , orient "auto"
            , markerWidth "15"
            , markerHeight "15"
            , refX "12.5"
            , refY "7.5"
            ]
            [ Svg.path
                [ d "M0,0 V15 M5,0 V15"
                , strokeWidth "2"
                , stroke "black"
                , shapeRendering "optimizeSpeed"
                ]
                []
            ]
        ]
    ]
