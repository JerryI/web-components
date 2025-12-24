BeginPackage["CoffeeLiqueur`Extensions`RemoteCells`", {
    "JerryI`Misc`Events`",
    "JerryI`Misc`Events`Promise`",
    "CoffeeLiqueur`Extensions`Communication`"
}]

RemoteCellObj::usage = "Internal representation of remote cell object on Kernel"
RemoteNotebook::usage = "Internal representation of remote notebook object on Kernel"

ResultCell::usage = "An access to an output cell generated during the evaluation"

EvaluateCell::usage = "EvaluateCell[cell_RemoteCellObj, opts___] programmatically evaluates a cell"
NotebookEvaluateAsync;
NotebookClose;

Begin["`Private`"]

Unprotect[CreateNotebook];
Unprotect[NotebookPut];
Unprotect[NotebookImport];
Unprotect[NotebookGet];
Unprotect[EvaluationCell];
Unprotect[EvaluationNotebook];
Unprotect[NotebookDirectory];
Unprotect[CellPrint];
Unprotect[ParentCell];

ClearAll[CreateNotebook]
ClearAll[CellPrint]
ClearAll[EvaluationNotebook]
ClearAll[EvaluationCell]
ClearAll[ParentCell]
ClearAll[NotebookDirectory]
ClearAll[NotebookPut]
ClearAll[NotebookImport]
ClearAll[NotebookGet]


Unprotect[NotebookPrint];
ClearAll[NotebookPrint];

Unprotect[NotebookWrite];
ClearAll[NotebookWrite];

System`EvaluationCell;
System`EvaluationNotebook;
System`NotebookDirectory;
System`ParentCell;
System`CellPrint;

NotebookPrint[___] := (Message["Not implemented"]; $Failed); 

(*  *)

cache = <||>;

(* the converter function takes file name and options as arguments *)
WLN`WLNImport[filename_String, options___] :=
 Module[{assoc, opts = Association[List[options] ], hash = CreateUUID[], fileHash = FileHash[filename]},
    If[KeyExistsQ[cache, fileHash], Return[cache[fileHash] ] ];

    assoc = Import[filename, "Text"];
    If[FailureQ[assoc], Return[$Failed] ];

    EventFire[Internal`Kernel`CommunicationChannel, "ImportNotebook", <|"Data"->assoc, "Hash"->hash, "FullPath"->FileNameJoin[{DirectoryName[filename], FileNameTake[filename]}], "Path"->DirectoryName[filename],  "Kernel"->Internal`Kernel`Hash|>];
    cache[fileHash] = hash // RemoteNotebook;
    hash // RemoteNotebook
]

ImportExport`RegisterImport[
 "WLN",
 WLN`WLNImport
]

Unprotect[NotebookSave]
ClearAll[NotebookSave]

Unprotect[NotebookEvaluate]
ClearAll[NotebookEvaluate]

Unprotect[NotebookOpen]
ClearAll[NotebookOpen]

Unprotect[CreateDocument]
ClearAll[CreateDocument]

Unprotect[NotebookRead]
ClearAll[NotebookRead]

CreateDocument[expr_, opts: OptionsPattern[] ] := CreateDocument[{expr}, opts]
CreateDocument[list_List, OptionsPattern[] ] := With[{uid = CreateUUID[], t = Flatten[transformCellExpr /@ list]},
    EventFire[Internal`Kernel`CommunicationChannel, "CreateDocument", <|"Hash"->uid, "List"->t, "Kernel"->Internal`Kernel`Hash|>];
    If[OptionValue[Visible] === True,
        NotebookOpen[RemoteNotebook[uid], "Window" -> OptionValue["Window"] ]
    ];
    RemoteNotebook[uid]
]

Options[CreateDocument] = {Visible->True, "Window" :> CurrentWindow[]}

NotebookPut[Notebook[args__], ___] := CreateDocument[{args}]
NotebookPut[Notebook[args_], ___] := CreateDocument[args]

NotebookWrite[RemoteNotebook[uid_], expr_] := NotebookWrite[RemoteNotebook[uid], {expr}]
NotebookWrite[RemoteNotebook[uid_], expr_List] := With[{t = Flatten[transformCellExpr /@ expr]},
    EventFire[Internal`Kernel`CommunicationChannel, "WriteNotebook", <|"Hash"->uid, "List"->t, "Kernel"->Internal`Kernel`Hash|>];
    RemoteNotebook[uid];
]


transformCellExpr[ExpressionCell[expr_, _] ] := <|"Display"->"codemirror", "Type"->"Input", "Data"->ToString[expr, StandardForm]|>;
transformCellExpr[ExpressionCell[expr_] ] := <|"Display"->"codemirror", "Type"->"Input", "Data"->ToString[expr, StandardForm]|>;

transformCellExpr[ExpressionCell[expr_, "Output"] ] := <|"Display"->"codemirror", "Type"->"Output", "Data"->ToString[expr, StandardForm]|>;

transformCellExpr[CellGroup[expr_List] ] := transformCellExpr /@ expr

transformCellExpr[expr_] := <|"Display"->"codemirror", "Type"->"Input", "Data"->ToString[expr, StandardForm]|>;
transformCellExpr[expr_String] := {
    <|"Display"->"codemirror", "Type"->"Input", "Data"->(".md\n"<>expr), "Props"-><|"Hidden"->True|>|>,
    <|"Display"->"markdown", "Type"->"Output", "Data"->expr|>
};

transformCellExpr[Cell[expr_String, _] ] :=  transformCellExpr[expr];
transformCellExpr[Cell[expr_String, "Output"] ] :=  <|"Display"->"codemirror", "Type"->"Output", "Data"->expr|>;
transformCellExpr[Cell[expr_String, "Input"] ] :=  <|"Display"->"codemirror", "Type"->"Input", "Data"->expr|>;
transformCellExpr[TextCell[expr_String] ] :=  transformCellExpr[expr]
transformCellExpr[TextCell[expr_String, _] ] :=  transformCellExpr[expr]
transformCellExpr[TextCell[expr_String, "Title"] ] :=  transformCellExpr["# "<>expr]
transformCellExpr[TextCell[expr_String, "Section"] ] :=  transformCellExpr["## "<>expr]
transformCellExpr[TextCell[expr_String, "Subsection"] ] :=  transformCellExpr["### "<>expr]
transformCellExpr[TextCell[expr_String, "Subsubsection"] ] :=  transformCellExpr["### "<>expr]

NotebookOpen[RemoteNotebook[uid_], OptionsPattern[] ] := With[{win = OptionValue["Window"], promise = Promise[]},
    EventFire[Internal`Kernel`CommunicationChannel, "GetNotebookProperty", <|"NotebookHash"->uid, "Function"->Function[x,x], "Tag"->"Path", "Promise" -> (promise), "Kernel"->Internal`Kernel`Hash|>];
    Then[promise, Function[path, 
        If[!FailureQ[path], 
            FrontSubmit[openNotebook[URLEncode[path] ], "Window" -> win];
        ]
    ] ];
    
    RemoteNotebook[uid]
]

NotebookOpen[path_ | File[path_], opts: OptionsPattern[] ] := With[{notebook = WLN`WLNImport[path]},
    NotebookOpen[notebook, opts]
]

Options[NotebookOpen] = {"Window" :> CurrentWindow[]}

NotebookSave[RemoteNotebook[uid_] ] := (
    EventFire[Internal`Kernel`CommunicationChannel, "SaveNotebook", <|"Hash"->uid, "Path"->Null|>];
    RemoteNotebook[uid]
)

CreateNotebook[_] := CreateNotebook[]

CreateNotebook[] := With[{uid = CreateUUID[]},
    EventFire[Internal`Kernel`CommunicationChannel, "CreateNotebook", <|"Hash"->uid, "Path"->Null|>];
    RemoteNotebook[uid]
]

NotebookSave[RemoteNotebook[uid_], path_String | File[path_String] ] := (
    EventFire[Internal`Kernel`CommunicationChannel, "SaveNotebook", <|"Hash"->uid, "Path"->path|>];
    RemoteNotebook[uid]
)

NotebookClose[RemoteNotebook[uid_] ] := (
    EventFire[Internal`Kernel`CommunicationChannel, "CloseNotebook", <|"Hash"->uid|>];
    RemoteNotebook[uid_]
)





pending = <||>;

NotebookEvaluateAsync[RemoteNotebook[uid_], OptionsPattern[] ] := Module[{}, With[{
    promise = Promise[],
    backPromise = Promise[],
    contextNotebook = OptionValue["ContextNotebook"][[1]]
},
    EventFire[Internal`Kernel`CommunicationChannel, "EvaluateNotebook", <|"Hash"->uid, "Ref"->contextNotebook,  "Promise" -> (promise), "Kernel"->Internal`Kernel`Hash|>];
    
    Then[promise, Function[data,
        If[FailureQ[data],
            EventFire[backPromise, Resolve, $Failed];
        ,
            EventFire[backPromise, Resolve, ImportByteArray[BaseDecode[ToExpression[data, InputForm] ], "WXF"] ];
        ]
    ] ];

    backPromise
] ]

Options[NotebookEvaluateAsync] = {
    "ContextNotebook" :> RemoteNotebook[System`$EvaluationContext["Notebook"] ]
}

Options[NotebookEvaluateAsync]

NotebookEvaluate::noninteractive = "Can't use NotebookEvaluate outside the interactive session. Please use NotebookEvaluateAsync"

NotebookEvaluate[RemoteNotebook[uid_], OptionsPattern[] ] := Module[{}, With[{
    promise = Promise[], caller = System`$EvaluationContext["Ref"]
},
{
    fullHash = Hash[{caller, uid}]
},
    If[!StringQ[System`$EvaluationContext["Notebook"] ],
        Message[NotebookEvaluate::noninteractive];
        Return[$Failed];
    ];
        If[KeyExistsQ[pending, fullHash],
            With[{res = pending[fullHash]},
                pending[fullHash] = .;
                Return[res];
            ];
        ];


        EventFire[Internal`Kernel`CommunicationChannel, "EvaluateNotebook", <|"Hash"->uid, "Ref"->System`$EvaluationContext["Notebook"],  "Promise" -> (promise), "Kernel"->Internal`Kernel`Hash|>];
        
        Then[promise, Function[data,
            If[FailureQ[data],
                pending[fullHash] = $Failed;
                EvaluateCell[caller // RemoteCellObj];
            ,
                pending[fullHash] = ImportByteArray[BaseDecode[ToExpression[data, InputForm] ], "WXF"];
                EvaluateCell[caller // RemoteCellObj];
            ]
        ] ];

        Abort[];
] ]

ParentCell[cell_RemoteCellObj: RemoteCellObj[ System`$EvaluationContext["ResultCellHash"] ] ] := Module[{},
    With[{promise = Promise[]},
        EventFire[Internal`Kernel`CommunicationChannel, "FindParent", <|"Ref"->System`$EvaluationContext["Ref"], "CellHash" -> (cell // First), "Promise" -> (promise), "Kernel"->Internal`Kernel`Hash|>];
        promise // WaitAll
    ] // RemoteCellObj
]

NotebookDirectory[] := With[{},
    With[{promise = Promise[]},
        EventFire[Internal`Kernel`CommunicationChannel, "AskNotebookDirectory", <|"Ref"->System`$EvaluationContext["Ref"], "Promise" -> (promise), "Kernel"->Internal`Kernel`Hash|>];
        promise // WaitAll
    ] 
]

EvaluationCell[] := With[{},
    RemoteCellObj[ System`$EvaluationContext["Ref"] ]
]

ResultCell[] := With[{},
    RemoteCellObj[ System`$EvaluationContext["ResultCellHash"] ]
]

EvaluationNotebook[] := With[{},
    RemoteNotebook[ System`$EvaluationContext["Notebook"] ]
]

RemoteNotebook /: Set[RemoteNotebook[uid_][field_], value_] := With[{},
    EventFire[Internal`Kernel`CommunicationChannel, "NotebookFieldSet", <|"NotebookHash" -> uid, "Field" -> field, "Value"->value, "Kernel"->Internal`Kernel`Hash|>];
    Null;
]

RemoteNotebook[uid_][tag_String] := With[{promise = Promise[]},
    EventFire[Internal`Kernel`CommunicationChannel, "GetNotebookProperty", <|"NotebookHash"->uid, "Function"->Function[x,x], "Tag"->tag, "Promise" -> (promise), "Kernel"->Internal`Kernel`Hash|>];
    promise // WaitAll
] 

RemoteNotebook[uid_]["Cells"] := With[{promise = Promise[]},
    EventFire[Internal`Kernel`CommunicationChannel, "GetNotebookProperty", <|"NotebookHash"->uid, "Function"->Function[x, (#["Hash"]&)/@x ], "Tag"->"Cells", "Promise" -> (promise), "Kernel"->Internal`Kernel`Hash|>];
    RemoteCellObj /@ (promise // WaitAll)
]



(* FIXME!!! NOT EFFICIENT!*)
(* DO NOT USE BLANK PATTERN !!! *)
RemoteNotebook /: EventHandler[ RemoteNotebook[uid_], list_] := With[{virtual = CreateUUID[]},
    EventHandler[virtual, list];
    EventFire[Internal`Kernel`CommunicationChannel, "NotebookSubscribe", <|"NotebookHash" -> uid, "Callback" -> virtual, "Kernel"->Internal`Kernel`Hash|>];
]

(* FIXME!!! NOT EFFICIENT!*)
RemoteNotebook /: EventClone[ RemoteNotebook[uid_] ] := With[{virtual = CreateUUID[], cloned = CreateUUID[]},
    EventHandler[virtual, {
        any_ :> Function[payload,
            EventFire[cloned, any, payload]
        ]
    }];
    EventFire[Internal`Kernel`CommunicationChannel, "NotebookSubscribe", <|"NotebookHash" -> uid, "Callback" -> virtual, "Kernel"->Internal`Kernel`Hash|>];
    
    EventObject[<|"Id"->cloned|>]
]

RemoteCellObj /: EvaluateCell[ RemoteCellObj[uid_] , OptionsPattern[] ] := With[{target = OptionValue["Target"], promise = Promise[]},
    EventFire[Internal`Kernel`CommunicationChannel, "EvaluateCellByHash", <|"UId" -> uid, "Target" -> target|>];
]

Options[EvaluateCell] = {"Target" -> "Notebook"}

RemoteCellObj /: EventHandler[ RemoteCellObj[uid_], list_] := With[{virtual = CreateUUID[]},
    EventHandler[virtual, list];
    EventFire[Internal`Kernel`CommunicationChannel, "CellSubscribe", <|"CellHash" -> uid, "Callback" -> virtual, "Kernel"->Internal`Kernel`Hash|>];
]

RemoteCellObj /: Delete[RemoteCellObj[uid_] ] := With[{},
    EventFire[Internal`Kernel`CommunicationChannel, "DeleteCellByHash", uid];
]

RemoteCellObj /: Set[RemoteCellObj[uid_]["Data"], data_String ] := With[{},
    EventFire[Internal`Kernel`CommunicationChannel, "SetCellData", <|"Hash"->uid, "Data"->data|>];
]

RemoteCellObj[uid_][tag_String] := With[{promise = Promise[]},
    EventFire[Internal`Kernel`CommunicationChannel, "GetCellProperty", <|"Hash"->uid, "Function"->Function[x,x], "Tag"->tag, "Promise" -> (promise), "Kernel"->Internal`Kernel`Hash|>];
    promise // WaitAll
] 

RemoteCellObj[uid_]["Notebook"] := With[{promise = Promise[]},
    EventFire[Internal`Kernel`CommunicationChannel, "GetCellProperty", <|"Hash"->uid, "Function"->Function[x, x["Hash"] ], "Tag"->"Notebook", "Promise" -> (promise), "Kernel"->Internal`Kernel`Hash|>];
    (promise // WaitAll)//RemoteNotebook
] 

CellPrint[any_, opts___] := With[{data = CellPrintGeneral[#, opts] &/@ Flatten[{transformCellExpr[any]}]},
    If[Length[data] === 1, data[[1]], data]
]

CellPrint[str_String, opts___] := With[{hash = CreateUUID[], list = Association[opts]},
    If[AssociationQ[System`$EvaluationContext],
        With[{r = System`$EvaluationContext["Ref"]},
            EventFire[Internal`Kernel`CommunicationChannel, "PrintNewCell", <|"Data" -> str, "Ref"->r, "Meta"-><|"Hash"->hash, "Type"->"Output", "After"->RemoteCellObj[ r ], opts|> |> ];
        ];
    ,
        If[!KeyExistsQ[list, "After"] && !KeyExistsQ[list, "Reference"],
            EventFire[Internal`Kernel`CommunicationChannel, "PrintNewCell", <|"Data" -> str, "Notebook"->First[list["Notebook"] ], "Meta"-><|"Hash"->hash, "Type"->"Output", "After"->RemoteCellObj[ r ], opts|> |> ];
        ,
            With[{r = If[StringQ[#], #, list["Reference"] // First] &@ (list["After"] // First)},
                EventFire[Internal`Kernel`CommunicationChannel, "PrintNewCell", <|"Data" -> str, "Ref"->r, "Meta"-><|"Hash"->hash, "Type"->"Output", "After"->RemoteCellObj[ r ], opts|> |> ];
            ];  
        ];  
    ];

    RemoteCellObj[hash]
]

CellPrintGeneral[cell_Association, opts___] := With[{hash = CreateUUID[], list = Association[opts],
    str = cell["Data"],
    type = cell["Type"],
    display = cell["Display"],
    props = Lookup[cell, "Props", <||>]
},
    If[AssociationQ[System`$EvaluationContext],
        With[{r = System`$EvaluationContext["Ref"]},
            EventFire[Internal`Kernel`CommunicationChannel, "PrintNewCell", <|"Data" -> str, "Ref"->r, "Meta"-><|"Hash"->hash, "Type"->type, "Display"->display, "Props"->props, "After"->RemoteCellObj[ r ], opts|> |> ];
        ];
    ,
        If[!KeyExistsQ[list, "After"] && !KeyExistsQ[list, "Reference"],
            EventFire[Internal`Kernel`CommunicationChannel, "PrintNewCell", <|"Data" -> str, "Notebook"->First[list["Notebook"] ], "Meta"-><|"Hash"->hash, "Type"->type, "Display"->display, "Props"->props, "After"->RemoteCellObj[ r ], opts|> |> ];
        ,
            With[{r = If[StringQ[#], #, list["Reference"] // First] &@ (list["After"] // First)},
                EventFire[Internal`Kernel`CommunicationChannel, "PrintNewCell", <|"Data" -> str, "Ref"->r, "Meta"-><|"Hash"->hash, "Type"->type, "Display"->display, "Props"->props, "After"->RemoteCellObj[ r ], opts|> |> ];
            ];  
        ];  
    ];

    RemoteCellObj[hash]
]

Options[CellPrint] = {"EvaluatedQ"->True, "Target"->"Notebook", "Window":>CurrentWindow[], "Title"->"Projector", ImageSize->Automatic}

End[]
EndPackage[]