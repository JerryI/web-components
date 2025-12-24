BeginPackage["CoffeeLiqueur`Extensions`NotebookStorage`", {
    "JerryI`Misc`Events`",
    "JerryI`Misc`Events`Promise`",
    "CoffeeLiqueur`Extensions`RemoteCells`"
}]

NotebookStore::usage = "Use it as an association NotebookStore[\"Key\", opts] to store object in the notebook, opts: \"Notebook\"->_RemoteNotebook object. See EvaluatingNotebook[]"
NotebookStoreAsync::usage = "Async version of NotebookStore"

Begin["`Private`"]

NotebookStore /: Keys[ NotebookStore[ ] ] := WaitAll[Keys[ NotebookStoreAsync[] ], 120]
NotebookStore /: Keys[ NotebookStore[ any__ ] ] := WaitAll[Keys[ NotebookStoreAsync[any] ], 120]
NotebookStore /: Set[NotebookStore[key_String, opts:OptionsPattern[] ], data_] := WaitAll[Set[NotebookStoreAsync[key, opts], data], 120]
NotebookStore /: Set[NotebookStore[nb_RemoteNotebook, key_String, opts:OptionsPattern[] ], data_] := WaitAll[Set[NotebookStoreAsync[nb, key, opts], data], 120]

NotebookStore /: Unset[NotebookStore[key_String, opts:OptionsPattern[] ] ] := WaitAll[Unset[NotebookStoreAsync[key, opts] ], 120]
NotebookStore /: Unset[NotebookStore[nb_RemoteNotebook, key_String, opts:OptionsPattern[] ] ] := WaitAll[Unset[NotebookStoreAsync[nb, key, opts] ], 120]
NotebookStore[key_String, opts:OptionsPattern[] ] := WaitAll[NotebookStoreAsync[key, opts], 120]
NotebookStore[nb_RemoteNotebook, key_String, opts:OptionsPattern[] ] := WaitAll[NotebookStoreAsync[nb, key, opts], 120]



NotebookStoreAsync /: Keys[ NotebookStoreAsync[ opts: OptionsPattern[] ] ] := With[{notebook = OptionValue[NotebookStoreAsync, opts, "Notebook"] // First, timeout = OptionValue[NotebookStore, "Timeout"]},
    With[{promise = Promise[]},
        EventFire[Internal`Kernel`CommunicationChannel, "NotebookStoreGetKeys", <|"Ref"->notebook, "Promise" -> promise, "Kernel"->Internal`Kernel`Hash|>];
        promise
    ] 
]

NotebookStoreAsync /: Keys[ NotebookStoreAsync[nb_RemoteNotebook ] ] := With[{notebook = nb // First, timeout = OptionValue[NotebookStore, "Timeout"]},
    With[{promise = Promise[]},
        EventFire[Internal`Kernel`CommunicationChannel, "NotebookStoreGetKeys", <|"Ref"->notebook, "Promise" -> promise, "Kernel"->Internal`Kernel`Hash|>];
        promise
    ] 
]

NotebookStoreAsync[key_String, OptionsPattern[] ] := With[{notebook = OptionValue[NotebookStoreAsync, "Notebook"] // First, timeout = OptionValue["Timeout"]},
    With[{promise = Promise[], internalPromise = Promise[]},
        EventFire[Internal`Kernel`CommunicationChannel, "NotebookStoreGet", <|"Ref"->notebook, "Key"->key, "Promise" -> promise, "Kernel"->Internal`Kernel`Hash|>];
        Then[promise, Function[r, 
            
            EventFire[internalPromise, Resolve, If[MissingQ[r], r, Uncompress[r] ]  ];
        ] ];
        internalPromise
    ] 
]

NotebookStoreAsync[nb_RemoteNotebook, key_String, OptionsPattern[] ] := With[{notebook = nb // First, timeout = OptionValue["Timeout"]},
    With[{promise = Promise[], internalPromise = Promise[]},
        EventFire[Internal`Kernel`CommunicationChannel, "NotebookStoreGet", <|"Ref"->notebook, "Key"->key, "Promise" -> promise, "Kernel"->Internal`Kernel`Hash|>];
        Then[promise, Function[r, 
            
            EventFire[internalPromise, Resolve, If[MissingQ[r], r, Uncompress[r] ]  ];
        ] ];
        internalPromise
    ] 
]

NotebookStoreAsync /: Set[NotebookStoreAsync[key_String, opts: OptionsPattern[] ], data_] := With[{notebook = OptionValue[NotebookStore, opts, "Notebook"] // First, timeout = OptionValue[NotebookStore, "Timeout"]},
    With[{promise = Promise[]},
        EventFire[Internal`Kernel`CommunicationChannel, "NotebookStoreSet", <|"Ref"->notebook, "Key"->key, "Data"->Compress[data], "Promise" -> promise, "Kernel"->Internal`Kernel`Hash|>];
        promise
    ] 
]

NotebookStoreAsync /: Set[NotebookStoreAsync[nb_RemoteNotebook, key_String, opts: OptionsPattern[] ], data_] := With[{notebook = nb // First, timeout = OptionValue[NotebookStore, "Timeout"]},
    With[{promise = Promise[]},
        EventFire[Internal`Kernel`CommunicationChannel, "NotebookStoreSet", <|"Ref"->notebook, "Key"->key, "Data"->Compress[data], "Promise" -> promise, "Kernel"->Internal`Kernel`Hash|>];
        promise
    ] 
]

NotebookStoreAsync /: Unset[NotebookStoreAsync[key_String, opts: OptionsPattern[] ] ] := With[{notebook = OptionValue[NotebookStore, opts, "Notebook"] // First, timeout = OptionValue[NotebookStore, "Timeout"]},
    With[{promise = Promise[]},
        EventFire[Internal`Kernel`CommunicationChannel, "NotebookStoreUnset", <|"Ref"->notebook, "Key"->key, "Promise" -> promise, "Kernel"->Internal`Kernel`Hash|>];
        promise
    ] 
]

NotebookStoreAsync /: Unset[NotebookStoreAsync[nb_RemoteNotebook, key_String, opts: OptionsPattern[] ] ] := With[{notebook = nb // First, timeout = OptionValue[NotebookStore, "Timeout"]},
    With[{promise = Promise[]},
        EventFire[Internal`Kernel`CommunicationChannel, "NotebookStoreUnset", <|"Ref"->notebook, "Key"->key, "Promise" -> promise, "Kernel"->Internal`Kernel`Hash|>];
        promise
    ] 
]

Options[NotebookStoreAsync] = {"Notebook" :> RemoteNotebook[ System`$EvaluationContext["Notebook"] ], "Timeout" -> 80}
Options[NotebookStore] = Options[NotebookStoreAsync]

Protect[NotebookStoreAsync]
Protect[NotebookStore]

End[]
EndPackage[]