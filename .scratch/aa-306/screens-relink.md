# Screens file relink log (AA-306)

Screens file jQqsc13MjOVaVST36jaxd8. Library 5JcAX6bwl48LqQhqcUuGOJ ("Fluidity  - Design Library", library key lk-ae55a994…). Date 2026-10-26.

## Progress

- [x] 1. Library reachable. search_design_system finds Button, Pill rim, text/primary, Glass/Body in "Fluidity  - Design Library". getAvailableLibraryVariableCollectionsAsync() in the screens file returns an empty list (library not enabled under Assets, Libraries for this file), but importComponentSetByKeyAsync, importVariableByKeyAsync and importStyleByKeyAsync all work by key (tested with Button, text/primary, Glass/Body).
- [x] 2. Key map built (below).
- [x] 3. Before screenshots
- [x] 4. Instance swaps
- [x] 5. Variable and style rebinds
- [x] 6. Verify
- [x] 7. Deletes
- [x] 8. Rename and note (file rename refused by Figma)

Screens file before work: pages Style Guide 2008:403, Tokens 2008:402, Atoms 2007:400, "Recording pill: Rim (approved)" 27:2, "Discovery · version 1" 2044:237. Local collections: Rim, "Color (superseded by Glass)", Dimension, Motion, Type, Glass · Color (Light 2021:5, Dark 2021:6). Local text styles Record/* (9) and Glass/* (7); effect style Elevation/Float. The library has no "Color (superseded by Glass)" collection and no Record/* styles.

## Key map: variable collections (library)

| Collection | Key | Modes |
|---|---|---|
| Rim | fe373b83e25c2b201ec17e6699f28dea37f8e54e | Approved=27:0 |
| Dimension | 285b3f857fdcdaa3aba5e90a892bc0405a1d02cd | Value=43:2 |
| Motion | 1089a61ac8a1409db3d415479eb1447772c917e1 | Value=43:3 |
| Type | 468503c4be3a8bbcd0490999a593ed10ca4aad40 | Value=43:4 |
| Glass · Color | eb5cf21776640d06dc606051f8fda0f3596e8c36 | Light=2021:5, Dark=2021:6 |

## Key map: styles (library)

| Type | Name | Key |
|---|---|---|
| Text | Glass/Title | 7d0d8b63766015e62f33b140aba8c55e26ff9cdf |
| Text | Glass/Section | 0d41f5f8c1f95d2f9f9039076963317248b489d5 |
| Text | Glass/Label | 9558f062132e5e0b9d55cd3b71a6f35bafd13922 |
| Text | Glass/Body | f04db6d44fb20c29ce23e31d47f7a07aea8cb8bf |
| Text | Glass/Transcript | 364bbfdbd50c45604065be28eb13fa0388cf2343 |
| Text | Glass/Detail | 0babdb0bdca22597ff4586b928a7100469cb3bf9 |
| Text | Glass/Small | 624be6bc60483d303552a1045f526bb306f86c48 |
| Effect | Elevation/Float | 06b5a726ba115d86fc351bd073e777279dadfa00 |

## Key map: variables (library)

| Collection | Variable | Key |
|---|---|---|
| Rim | rim/width | 45b43c343f829950cdda86d576dbba24d610d7a7 |
| Rim | rim/width-gain | ed49fece5f72fa125dd3ea828d5896b0786d2e70 |
| Rim | rim/glow-reach | 700c8fbdb7ff9432ee7caaafff91be8eeb53ff12 |
| Rim | rim/glow-strength | 22081ad57909e2da81565b097a96c7c7d6b3bb66 |
| Rim | rim/intensity | b35bcb165a3792909e4f093b0055bc9c19b666b0 |
| Rim | rim/contrast-quiet | 930ba6513412bd5bb328d55fbbd53e5c8f78c5a7 |
| Rim | rim/contrast-speaking | e01da1226c8954e71a39d34e0e22c5087531225e |
| Rim | rim/light-quiet | 9eaf9e61b5b30801f8ff5e02ab99ee135912bdc6 |
| Rim | rim/light-loud | 0b540f502a681c2a611a774bb7ff7c3bfbe7b541 |
| Rim | rim/band-lift | b7d15edb79b9b97e8e7c7c4292436b1b3bfa290c |
| Rim | rim/slide-idle | 2a4fe3b2ec6c635ab18411473ab124bcf5a5710f |
| Rim | rim/slide-speaking | 97446092bb97aad778ccbba696b5a3297807936e |
| Rim | rim/bloom | 131cbca4decc09fbcba4c7b982c5ab28222c9cb5 |
| Rim | rim/bloom-decay | 5cec9210e3306ba4ca789d9194e3399560b87453 |
| Rim | rim/bloom-width | d0a1d4cc6a1bc372300d7240fa3865d3c599c628 |
| Rim | rim/bloom-spread | bd81ba42d6951753d7363806e80ca35b62520f33 |
| Rim | rim/hue-shift | 8c6265ea855ac1c4f2d67db160125a935ae7e61b |
| Rim | rim/hue-cycles | 81a43e9b280afb3162410e3c31bdf4dabd0609c4 |
| Rim | rim/tilt | 667cdc5910a430e27ffc368da7d35235afebcb97 |
| Rim | rim/attack | 3d42fd33cb6e7c208480f821014622a60d72c9bc |
| Rim | rim/release | 0ce9314f221a15c1326f60f3288ae4875de6d544 |
| Rim | rim/idle-activity | f28cf68cc47c5399b630e9dc506188e485751905 |
| Rim | rim/idle-fps | 780af20b7798ae8ec57664c9c68872c6afbb9f7c |
| Rim | line/length-ratio | ae9dbdc4e31f38f5daee109ab39b89ff89055bca |
| Rim | line/width | e07704bda2845453d655485373cdee58187a47d1 |
| Rim | line/glow | 64991bad0732bb57d6b0fbaff6af0acf4062e2e6 |
| Rim | line/breath-depth | 38dbc2093bb5aaa08171da93e8c236a2ef58e8ce |
| Rim | line/breath-period | ff78f9551be71a2f29acc3c8e303b17ccdc2b6e5 |
| Rim | line/blooms | 288947ee5879ca7a88fb4988ec23979d591b7598 |
| Rim | motion/download | 653cc951bfafeff4ebe398e8bf8c058d10d701c2 |
| Rim | motion/green-hold | 9e239bd9adb8110d0225e715f766189c2fc1676a |
| Rim | motion/expand-back | f307b8e60cc6258e432c7541bb1a970cfb9520ab |
| Rim | motion/collapse | ac4036520e4f024b5189ef1cccaa5a357552bc02 |
| Rim | motion/appear | 6dc3a9c07ba241ba5d9f8976d8008cb21df8ec4a |
| Dimension | space/1 | e982d2282cdee243d9a9884770ef6f3781f43307 |
| Dimension | space/2 | 611aafd30349a85bffb322d8737da44b180d1cb1 |
| Dimension | space/3 | 5fa8680baeb1943921cc9ec7a2d0d447ba1526b1 |
| Dimension | space/4 | 0b225846033f5827bc32bed70ce2e2c2ec00639d |
| Dimension | space/5 | 12f1f82f9d00a789a4069136139cd1d2b185e330 |
| Dimension | space/6 | 4cc3b6975eacfeef80aa5b12cf03c9355c4497b3 |
| Dimension | space/7 | 2e9fb757e76052391c616d7651ffc6da3213c1e8 |
| Dimension | space/8 | 49af0b75e7f60f7bd0449f1207565ea39561685a |
| Dimension | space/9 | b71138b18afccfce6247e05acd45667a88ebbc3e |
| Dimension | space/10 | 5e0f9d67f3f1ce8648005e6afefc97846173072a |
| Dimension | size/control-s | 1fa696f052942773fa07d9c7b19537fa23be45e2 |
| Dimension | size/control-m | 72c31930849b475b3d22a9d99d3128ffa8940eb9 |
| Dimension | size/control-l | a2563bf55aec5c71f8d678b992d938c0bda7a27d |
| Dimension | size/row-min | 58bde2cfc41ac738f428e5e93e29fbcd25e97094 |
| Dimension | size/sidebar | e2286589b83d52689300cc97909efdc4087d22b3 |
| Dimension | size/icon-s | 7c91b5745e880285b973f0a742bc62c74fc9d0bf |
| Dimension | size/icon-m | 9d9b6f3ccff45bb9d363a58a3ef6ce2966864c1f |
| Dimension | size/icon-l | 912bf78ebf549466ac36cdc7dcee07bd22c58264 |
| Dimension | radius/capsule | 9652099ccca474803671fd474246f4bb4af71e53 |
| Dimension | radius/container | e6c9d2a1b8ae225d2af90665d7a3e3b5462c8cab |
| Dimension | radius/inner | 6ae67b7e08b3bbbcc06bc0158c37299dbdfec153 |
| Dimension | radius/window | 4d07c0a2c7c26ff3043e83220c8b9bb37dfb7e08 |
| Dimension | line/hairline | d9a95fd998ce1746a340cf5a7ced369ef294abb6 |
| Dimension | line/focus | aee15a6873afd45ed45db2bd0c6416de25d9bda0 |
| Motion | duration/snap | dbfe5ab938ce692574eb051ed8253ba5015fad92 |
| Motion | duration/exit | 12600ebbd5d77bf8895f6bc83edf2960567d9aaa |
| Motion | duration/enter | bf39df2b677aa32097c4d470a2f47a7abde828b8 |
| Motion | duration/hold | cd2b68fd878a11aeb4c0093e898ba45eb4796bb9 |
| Motion | duration/collapse | 8c5ce8d1f9d23ab5f15d02025ce43d610ee3d274 |
| Motion | duration/reduce-crossfade | e1716967821864e56ef7455c5c4eb5892fd00689 |
| Motion | spring/size-damping | 0b5f915e16ba680357f599b9d5ebfd8aba86a682 |
| Motion | spring/size-response | ae6b22b3a0ce9ba9de473e7892ac3b79c42f7c6d |
| Motion | spring/collapse-damping | 4f3fb7ae101baeb69feb050b3f88f42a4d9bdf61 |
| Motion | spring/collapse-response | 8d4e4ce9a5be595ef25322f4d2a51199d3a3c069 |
| Type | font/family | 92670c5628fa40229c66dc2d82d7ea06b42b3284 |
| Type | size/title | 3c833cdaa3d55d46caeab99a5fdd43441a3ddc5a |
| Type | size/section | 3133fe9ccc16fac26cf2d9c9f99a9d3ca37e945d |
| Type | size/transcript | f613131ceb6f01df2d49fed44a33e09b8324ead4 |
| Type | size/body | 9ee773943ce56491694a9cd4332ea49975eeb5a5 |
| Type | size/label | 768ace2c8bb89cdee0d9843c2ba90cf3f8c4ae0d |
| Type | size/detail | c819d544fb569506685d8f57e49b7bda50c92bea |
| Type | size/small | 42062b6c25560896079a85498486d675acb04117 |
| Rim | bubble/offset | 65fa38d9f8b81742a284bb9c7c714dec71146a4e |
| Rim | bubble/max-width | 97c215de9eb2f16227cface52586d227c9d48ad6 |
| Rim | bubble/max-lines | 295bbd99b53a0caeca021b815195196492fcb9b6 |
| Rim | bubble/text-size | 9673332f4515f4d023d1e91c5b135b9d86d90daf |
| Rim | bubble/line-height | 35965bef521f15a309cacf35f3bb475ffab97011 |
| Rim | bubble/padding-x | d753cde93c101e0fb20681813296760faa71e601 |
| Rim | bubble/padding-y | 4afd291d850bd581dc0a83c8b41d7816468165d5 |
| Rim | bubble/radius-max | 202dc364872f72fd9a66dc4940696f15461c15f3 |
| Rim | bubble/ring | 1b531d5353604ea02fb034bb1b328be191a8ece9 |
| Rim | bubble/blob-radius | a4ee61dd5e9ff88ee4c07316e30299a7071ffdb6 |
| Rim | bubble/blob-radius-settled | d9c58c318bc5fe1e01412511af745626c558531c |
| Rim | words/batch-interval | 2b92e756258f9462cc0b33a635eaf9bbf41a9566 |
| Rim | words/word-gap | f52c83ff3d81b187030d9cc7567032b3c7d6a51d |
| Rim | words/confirmed | c5832cf2c91fd387e59378a32d0db5ea57ebb901 |
| Rim | words/pending | 98358ac9e389290f90f3cce8a845c6b81dbfe305 |
| Rim | words/processing | ee425af2bce84ab978cc36b51afa0f439108384e |
| Rim | waveform/window | e734ec011440ddf5b40abb21c90708223905c86f |
| Rim | waveform/flatten | 21151cd14283eb44944a4c8985b829d20e6b9d16 |
| Rim | waveform/glow | fe96f35e54104b8b9565c67708f2e8b96377f2c8 |
| Motion | spring/layout-damping | d68b55b6e0646145b5f284b2f7c292839fad3c70 |
| Motion | spring/layout-response | e27752d5535c1634ad50182d41cd141c56ed9cf6 |
| Motion | spring/recombine-damping | 9bee44de72e4f8d7bc979bc9f2571543565d1ed5 |
| Motion | spring/recombine-response | 02b0b1f6f2bd4cecfeed7e49876e865e989d9696 |
| Motion | spring/split-damping | ff8b65d171b20180d789545c6a02be6bf8f559ee |
| Motion | spring/split-response | a9c1c40837e9699f46c5216d5a8c855ee0f53a33 |
| Motion | spring/split-head-start | ec12a4014d1040e1d1a89d487c59f183f5aa58f2 |
| Glass · Color | surface/window | 526afbd246008c2d9ef88cfe8644205bf5396065 |
| Glass · Color | surface/sidebar | 8bafcc781f94d60bb42fe8460be05311815ec3ca |
| Glass · Color | surface/raised | e2343cfccbb79db9df2720712c1cbca31875e645 |
| Glass · Color | surface/selected | 94b3a662627f0ff7ce9c6fcc943c95679736ebf3 |
| Glass · Color | surface/hover | a6eafc7b2983c69560b425672dd8b33430220a44 |
| Glass · Color | line/rule | 9a6d4c54d503d11f7be2b2012158c835281f9341 |
| Glass · Color | line/strong | a0d93f41396f888f5f75f222eb472ff9d36e9565 |
| Glass · Color | text/primary | 7c6063e2cbe09b2006f3dd7bf85f1f2e1f8b2a52 |
| Glass · Color | text/secondary | f5badd1af64efeab0182d67f731f945813419f7f |
| Glass · Color | action/primary | f8534badf147c05dfe018ace24f38698057b252c |
| Glass · Color | action/on-primary | d4aae7d917b4d6a61f9d869386f491ca91661518 |
| Glass · Color | state/done | 1415d7932ca2e641bf77300c0ed8387f7d795879 |
| Glass · Color | state/attention | e333acb4c57426cc7b2bc8cafa7e618e1d47ed71 |
| Glass · Color | state/retry | f1599a3613d27082752d1da3c97cc2e14b8985e0 |
| Glass · Color | state/destructive | 387d3c0d70f9a19e66a3c859301ea9196d919f5f |
| Glass · Color | live | 4b665c695f4f3f8109a0f4be7bea08910bfffd06 |
| Glass · Color | control/knob | e427da2d4643a6aa7b529a1061d0bf494c1e8b91 |
| Glass · Color | focus/ring | 582f0d335d75c207e47338ab4c9d58484d5a9c20 |
| Type | font/family-rounded | fc645e7141baa37da6dbf079cf9aa84803069d7e |
| Type | line-height/title | 3599bf855d35d6f26660df0626d8021512bc6c06 |
| Type | line-height/section | 8d33cb4a2efdf62dc81b6fac8ac64cd38549c165 |
| Type | line-height/label | a1dfac09786db6b36f92742718741f85683ec497 |
| Type | line-height/body | 93807a787da685992b20abc11882de141e0934d2 |
| Type | line-height/transcript | d211504bca79dce8dc72c5888e2586ca9a6203c5 |
| Type | line-height/detail | ad6bfbba028eaae5d814689dc12722bfb8f1be1e |
| Type | line-height/small | f439298c7eedaea873dc6a39b4eceb3dcc65764d |
| Dimension | size/icon | 715ada5168342dca70695e998d8816451a8d929f |
| Dimension | size/icon-xs | f0a36a771622ead8ae0fb68c4dfff94d8a6e1362 |
| Glass · Color | line/lit-edge | 68df2fa23dd4673072899180383d31b344a28bf1 |
| Glass · Color | pill/body | 4072b1f51bd03fc9da442be0cc22216d74933da2 |
| Motion | duration/hide | e7f6e1b24d1ffccdc278df135c9630b671e435cd |
| Motion | duration/fail-flash | c5312655f69d119f8cebbe43eb1d87bd9796d71e |
| Motion | duration/shortcut-flash | 76c175e9450647a48bf52a8c0f23a5904f743fdf |
| Motion | spring/press-damping | 7489f09c1b77fcd90e4d2da83769134ce58c46b5 |
| Motion | spring/press-response | 6e60ef82d5e586b6b183d627f1153e267fdf38f9 |
| Motion | spring/shake-damping | 13de798fb3557c688d2dcf6d8acf00c43018267b |
| Motion | spring/shake-response | a0eee3a7522354bec1a0585f06885e84b374f292 |
| Motion | spring/drag-damping | f6bf54ad258ad1b8aed01eaeebaa07e6fcd5e04e |
| Motion | spring/drag-response | a80c562358d9116a97b674cf5f22301b6c0966fb |

## Key map: components (library)

Type: S = component set, V = variant inside a set, C = component outside a set.

| Page | Type | Set or component | Variant | Key |
|---|---|---|---|---|
| Atoms | C | Icon/General |  | c161c80beaef1bca6ba97ae60a33ee74cfc339d8 |
| Atoms | C | Icon/Cleanup |  | f9dad60363aa360e0a88d2b0585ed675456cd5f3 |
| Atoms | C | Icon/Words |  | a512948170cff2ab27ac90dfc49b72b1f467c82d |
| Atoms | C | Icon/Permissions |  | a372481d67d044a847facc3a9cd3edcc19eb5c0d |
| Atoms | C | Icon/Microphone |  | 6e7fb9e008a0d73f7607c026191495e4eb02720c |
| Atoms | C | Icon/Chevron up down |  | b4ae2b08f7e7ac2e60d0199bc80accdc1d058937 |
| Atoms | C | Icon/Check |  | 28fb0b353b463b7dcd9c4154393a4cf7230fb2c8 |
| Atoms | C | Icon/Info |  | caf47106d31a82ec1c6129265b62760cb96c58ac |
| Atoms | C | Icon/Close |  | 9fa705d39fa1f60214243225cbc506b8f00767ef |
| Atoms | S | Button |  | 64f7e2c1f7bbe49c6d9e31dae2e4354c36dbd720 |
| Atoms | V | Button | Kind=Primary, State=Default | 9467661ffa3fff7d871d2f6b52b3fc119fc14349 |
| Atoms | V | Button | Kind=Primary, State=Hover | 82cb1fd705372216ba5196520805be6416ee640e |
| Atoms | V | Button | Kind=Primary, State=Pressed | 8cfde01bb6d165f9dcae922a77c58febe38bf53b |
| Atoms | V | Button | Kind=Primary, State=Disabled | ca68a9510252262cf63662f5c2e5ed150d90c2da |
| Atoms | V | Button | Kind=Secondary, State=Default | 25b9a2bbcbf10e0a8d4514b99dedbb355431fe9f |
| Atoms | V | Button | Kind=Secondary, State=Hover | 0421ee654bceb996952de94add249f74fca7d730 |
| Atoms | V | Button | Kind=Secondary, State=Pressed | e1c3e5c71912a50d4efa976e97d988fc2ab7cd0b |
| Atoms | V | Button | Kind=Secondary, State=Disabled | 29e5b7d840a678d1044d7a923c31d10042640039 |
| Atoms | V | Button | Kind=Quiet, State=Default | f4a5c462d1e041e78084e7f33cdc1a5ffae3985f |
| Atoms | V | Button | Kind=Quiet, State=Hover | 9b0ca6bd54a23bd7865517c7abf806c2f23f51d6 |
| Atoms | V | Button | Kind=Quiet, State=Pressed | ce316384e72f155f2c41adddd7a57df112e96480 |
| Atoms | V | Button | Kind=Quiet, State=Disabled | c2f4828ad73f74d3f53a5490ef4f50df78b4fab9 |
| Atoms | S | Toggle |  | c4fe8a6a6679ea2065a83b1ead6d54fa7533bcb3 |
| Atoms | V | Toggle | Value=On, State=Enabled | ee25924f517eace7775d08455f678882e7fca7f8 |
| Atoms | V | Toggle | Value=On, State=Disabled | 285790fd163f97ca3f19b91cfcb2ce9acd08d114 |
| Atoms | V | Toggle | Value=Off, State=Enabled | 72c1a481c81098d91ff56b9b01be62b97d2449f6 |
| Atoms | V | Toggle | Value=Off, State=Disabled | 09989adca9aa64b364e0fb75a2d8df85d29fa063 |
| Atoms | S | Text field |  | dcea97c6498bb023686b3f6155f730f922ec1bdf |
| Atoms | V | Text field | State=Default | a52c3941c55a7208b082fd0de8581d2af50e5d4a |
| Atoms | V | Text field | State=Focused | f3bf7a2ca9345ea8737bd9c51e8c6db2b2558b9d |
| Atoms | V | Text field | State=Error | 891fd4ce78dd16ad4213ecdd122e4d4e109390c2 |
| Atoms | S | Pop-up button |  | 8d32bb850f43230cfa2a7bd893b69994c6ee3802 |
| Atoms | V | Pop-up button | State=Default | 018d5680d99b3921581d4c024c9a6887adb9932b |
| Atoms | V | Pop-up button | State=Open | 503d36b8f4e3e8498d3009b561f66b6a66fad860 |
| Atoms | S | Segmented control |  | ccfac3964dd78675a51326f0ec578ba48ea633e5 |
| Atoms | V | Segmented control | Selected=Small | 1a2ed362e31061b50a5cd1d622a3a5c492785b82 |
| Atoms | V | Segmented control | Selected=Medium | bed6e2bb6a7da808a30d74ce8e65d91a0e3d3e88 |
| Atoms | V | Segmented control | Selected=Large | 72c20e22bfbe13bb27166318a123d8b42a3cb2e0 |
| Atoms | S | Sidebar item |  | 1de6f7871a1fd0de1d58a14a21bcdbf70fd35d59 |
| Atoms | V | Sidebar item | State=Default | 84dff53a828c885f4d8851b75512cda7e2d08383 |
| Atoms | V | Sidebar item | State=Hover | e48f76facee459dd844334ba5b4baac7887b768d |
| Atoms | V | Sidebar item | State=Selected | 71a3aa8387a81f2d01594477b261ce654ed59b82 |
| Atoms | C | Section header |  | a328084e907f24f0b693ffc7149ab03c6cb27419 |
| Atoms | S | Shortcut recorder |  | 8a0cba5ef1e0bbb6d2b8f9eaf99089ce5ef23e6c |
| Atoms | V | Shortcut recorder | State=Idle | 8488ff0049bb08e728b08c2855b5f26aae2fd577 |
| Atoms | V | Shortcut recorder | State=Recording | 0add806762c69f166c8532268094d06a9abe8992 |
| Atoms | V | Shortcut recorder | State=Set | 3976a3b833180c9e696480935978823efefc212d |
| Atoms | S | Status row |  | 16cab452fc245719125ee19bae6119d56a1485d1 |
| Atoms | V | Status row | State=Done | 698d6760a065f9e5eda421844aabf6346cc0f0f8 |
| Atoms | V | Status row | State=Attention | 0f1d14b344cb6ab9fbfb6fd73e838ad0068df886 |
| Atoms | V | Status row | State=Retry | ef9ace0a73d07c9dc2c8a9f9149a3fa7ee74e2ee |
| Atoms | S | Focus ring |  | 8e7b15cc5eb04204286b8c13b32664921e0f22d9 |
| Atoms | V | Focus ring | Target=Button | 6158349477281c634b1f4a308ec403ff2fdc2d9c |
| Atoms | V | Focus ring | Target=Toggle | 15e53a37753d906b66310301b248acaec50373c2 |
| Atoms | V | Focus ring | Target=Segmented control | 2975bbb6e91d43c0707470975a265bb95f74b761 |
| Atoms | S | Menu bar popover |  | 88f1d3e6386bc5383eb1e4453c3c2700ee608a7f |
| Atoms | V | Menu bar popover | Status=Ready | 26e3565a3caa2f3df5ed24ea9ec640da70342e9f |
| Atoms | V | Menu bar popover | Status=Listening | 9cc6aadab5c89ff12d6b4819ce505e8a982d3209 |
| Recording pill: Rim (approved) | S | Pill rim |  | 1b7d5dd59ddf9831023f208a1dd8970fc31492cb |
| Recording pill: Rim (approved) | V | Pill rim | State=Hidden | a3561ac43d1350b1ae379f966cd4db3ecb0f32ea |
| Recording pill: Rim (approved) | V | Pill rim | State=Appear | 2d1ca501320432163d881ef971f343dbd7c75822 |
| Recording pill: Rim (approved) | V | Pill rim | State=Rest | b9dcab35c116bebfc6e248cd501a065dea73a071 |
| Recording pill: Rim (approved) | V | Pill rim | State=Listening | ced45218fc42debdf19c682a901cdbba42c9f3a2 |
| Recording pill: Rim (approved) | V | Pill rim | State=Processing: download | 8c091cb18728f852ee400c1ee6060cc081edd7ae |
| Recording pill: Rim (approved) | V | Pill rim | State=Processing: line | 4a9cfa42d32f18e614538160f6d162713d70d0fd |
| Recording pill: Rim (approved) | V | Pill rim | State=Complete: green line | 071dfd5e88347a63016cc928b44533d7bddd1086 |
| Recording pill: Rim (approved) | V | Pill rim | State=Collapse: swell | 9e023f19367885d12229f7b273ca903cad5c67d5 |
| Recording pill: Rim (approved) | V | Pill rim | State=Collapse: closing | 79aa13b6ad855d0619233855b9117f249d4f373c |
| Recording pill: Rim (approved) | V | Pill rim | State=Collapse: last glow | d4f9dae8ca1272cbc1c1cf163b6b3583a2a10e38 |
| Recording pill: Rim (approved) | V | Pill rim | State=Complete: expand back | 2a87c2a6eb112b61266815e045e10c62d24c083e |
| Recording pill: Rim (approved) | V | Pill rim | State=Collapse (alternative): line then point | 531341f927f5469f9599a69bf1c0be734d273054 |
| Recording pill: Rim (approved) | V | Pill rim | State=Mic lost: fix bubble | 1bb6206f316b34adcf1c6c629e2cca747515c226 |
| Recording pill: Rim (approved) | V | Pill rim | State=Permission revoked: fix bubble | 5f0559bd8018d244d0e4ae5fbcf310946fc9a3d8 |
| Recording pill: Rim (approved) | V | Pill rim | State=Paste failed: split | 794dda27d534864631eb113eb7f164204c1e1e14 |
| Recording pill: Rim (approved) | V | Pill rim | State=Paste failed: waiting | 84d9c6e9621a86ec3387861f521bb67e6f5501b2 |
| Recording pill: Rim (approved) | V | Pill rim | State=Paste failed: hover | 36787522c765981b0198b4a3d5672b3fa401a7ca |
| Recording pill: Rim (approved) | V | Pill rim | State=Retry failed: soft orange | 777fba536d1a911fe98120fdb79eea66ced4c32d |
| Recording pill: Rim (approved) | V | Pill rim | State=Retry worked: green and bubble dissolves | b4d36e35d196699c465e7f86ac60afa9c78eda95 |
| Recording pill: Rim (approved) | V | Pill rim | State=New dictation: merge back | 7c448353739848acf557be68c7520785b369d8ce |
| Recording pill: Rim (approved) | V | Pill rim | State=Can't hear you: light nudge | 2f49ae9efc3049a8e00dc581f8e78fa1a326226e |
| Recording pill: Rim (approved) | V | Pill rim | State=Dragging: stretch | 5ef19d8a7799f90f9ab67ec2b0c87e07bcb2800b |
| Recording pill: Rim (approved) | V | Pill rim | State=Paste failed: waiting (docked right) | 9298267a259a0855fe15deceb26b6640cbdc7073 |
| Recording pill: Rim (approved) | V | Pill rim | State=Live words: waveform | 73844f3c0e654a199b49323959090b85784b2296 |
| Recording pill: Rim (approved) | V | Pill rim | State=Live words: first word | 27a444ff9d93ba57365bdba6f06ee6e3fd330969 |
| Recording pill: Rim (approved) | V | Pill rim | State=Live words: one line | 2892ba9d0f98d049b16ffe3d8d752d8a0bfabb77 |
| Recording pill: Rim (approved) | V | Pill rim | State=Live words: six lines | be14aa97a59e840ab42697f181adfa5615b62524 |
| Recording pill: Rim (approved) | V | Pill rim | State=Live words: release | d96fb53eb149f733b11e230423dde20441f41264 |
| Recording pill: Rim (approved) | V | Pill rim | State=Live words: pasted | adaec473c10f5d55b1dd903c003eed08e0617119 |
| Recording pill: Rim (approved) | V | Pill rim | State=Live words: absorbed | 04316d19268aa4e02ebf7833cbd649bd54181415 |
| Discovery · atoms and components | C | Icon/Copy |  | 7f8d5d8142b5bb390c2007a8a505666c273af9df |
| Discovery · atoms and components | C | Icon/Paste |  | 2df2698822841b0323bd06adfa680d8504d12589 |
| Discovery · atoms and components | C | Icon/Plus |  | d70086c1158e517951852c68f16540be9bce07b1 |
| Discovery · atoms and components | C | Icon/Minus |  | 77ddfbd1daa76484bcc1a63e3ecf94f3be6c424e |
| Discovery · atoms and components | C | Icon/Trash |  | f710647fbfd2cda9a173b1e0a577a095f04ce99f |
| Discovery · atoms and components | C | Icon/Accessibility |  | ced8eda733f4dffcc0ca10c5dc7014673ab315f6 |
| Discovery · atoms and components | C | Icon/Eye |  | fb9827e4a45266dd6d8d5995865cb3b8bb6b2da6 |
| Discovery · atoms and components | C | Icon/Eye slash |  | 7d88b887ac9ad3d286b84b79991137942bba1eb7 |
| Discovery · atoms and components | S | Menu bar icon/Pill outline |  | 3f9d7fd5a2c9e890a160c422f0c247923c591a5a |
| Discovery · atoms and components | V | Menu bar icon/Pill outline | State=Ready | b5f00f1e16be5d1cf1c6a35d964c33d8bb1274d8 |
| Discovery · atoms and components | V | Menu bar icon/Pill outline | State=Recording | efa85db086b8ce955911530ff94a788ad090c704 |
| Discovery · atoms and components | V | Menu bar icon/Pill outline | State=Mic warm | 513f893cdaeafcdbf9ebe62f43f53d0062a0c995 |
| Discovery · atoms and components | V | Menu bar icon/Pill outline | State=Cleanup off | a49b1c92ee85085852c8907e6a5303e53336e225 |
| Discovery · atoms and components | V | Menu bar icon/Pill outline | State=Permission missing | 8de1b425fe3e1e095219685db5ef027fb9b126a7 |
| Discovery · atoms and components | S | Menu bar icon/Microphone |  | b0e180da381ef765acf2fc7ed2e8a25e11769264 |
| Discovery · atoms and components | V | Menu bar icon/Microphone | State=Ready | e8b395b30bb3e60a7da78b9819f3b68012d9e370 |
| Discovery · atoms and components | V | Menu bar icon/Microphone | State=Recording | dea2dea6a575e12c43291925e3499f1c1fb0f943 |
| Discovery · atoms and components | V | Menu bar icon/Microphone | State=Mic warm | c5d034fb281c64f0bafe82f5e5c8fd1e3a63ca8a |
| Discovery · atoms and components | V | Menu bar icon/Microphone | State=Cleanup off | aafa496c7105603ff56409c707b638f0e8838d51 |
| Discovery · atoms and components | V | Menu bar icon/Microphone | State=Permission missing | c8fdc4c15841790dc186cd666b99f2a60211e038 |
| Discovery · atoms and components | S | Menu bar icon/Dot and pill |  | 2bfa826e62dd35bb9f80ad9788e7f59ebb8a96a2 |
| Discovery · atoms and components | V | Menu bar icon/Dot and pill | State=Ready | 5e9bcd997800b9d63704a33a5226a3e5c790d48a |
| Discovery · atoms and components | V | Menu bar icon/Dot and pill | State=Recording | 750a1a46af1c7bd3dd1018becf3e2426d8a3c388 |
| Discovery · atoms and components | V | Menu bar icon/Dot and pill | State=Mic warm | a3039aaa1d452873b6ef4b5b428f5d2902da8ef3 |
| Discovery · atoms and components | V | Menu bar icon/Dot and pill | State=Cleanup off | 22a96bb5aa4766429c72d12505f21a5f85fb8153 |
| Discovery · atoms and components | V | Menu bar icon/Dot and pill | State=Permission missing | 2c427882bc5c055337057d6d29bc1fe39a840d15 |
| Discovery · atoms and components | S | Status dot |  | 0b73a837bc5b51ebfed4bd9c3db536d21eac3b89 |
| Discovery · atoms and components | V | Status dot | State=Ready | fb51c12b715d6627ec5cf8b48d6507717f0ed7bc |
| Discovery · atoms and components | V | Status dot | State=Listening | f23482e084f7e21558827ee30247a7bf8a42cef9 |
| Discovery · atoms and components | V | Status dot | State=Mic warm | dd77e1053950608b2897c36cf20c9c3d4c6aa2ef |
| Discovery · atoms and components | V | Status dot | State=Cleaning up | ef2f870ef4f608669f11bd033469986b2a7079f0 |
| Discovery · atoms and components | V | Status dot | State=Attention | d44fc5421a893bb22a1953ae31c52b5becd1d1a9 |
| Discovery · atoms and components | C | Keycap |  | 14ec07f8f5ebf4b9558e4413a5328c4a9efb5645 |
| Discovery · atoms and components | S | Icon button |  | 0d03be8d85a59eb9f652b0fb270ac43e3203ac39 |
| Discovery · atoms and components | V | Icon button | Kind=Quiet, State=Default | 4f5e34e032b95f62f1abe62d0db06e9ae8f66b48 |
| Discovery · atoms and components | V | Icon button | Kind=Quiet, State=Hover | 89be5285a1cf061d4ae6cee124c8aec1655a1c2e |
| Discovery · atoms and components | V | Icon button | Kind=Quiet, State=Pressed | fb9d55c6a187ebdb342d5302f5b32e5671c6be02 |
| Discovery · atoms and components | V | Icon button | Kind=Quiet, State=Focused | 6d2d2c3080944d482c3ae5f9170c7987c8e133bd |
| Discovery · atoms and components | V | Icon button | Kind=Quiet, State=Disabled | 45ee2c6cded698f87b69c41b85be56b7a0b4ab28 |
| Discovery · atoms and components | V | Icon button | Kind=Destructive, State=Default | 0f1d33f66d460c3606756be88d28006408c600fd |
| Discovery · atoms and components | V | Icon button | Kind=Destructive, State=Hover | 9c563da80a8c6232029a56f40642ad78c732bb0b |
| Discovery · atoms and components | V | Icon button | Kind=Destructive, State=Pressed | dff122b0b347e3da58a050d9c445ec5f7a14874c |
| Discovery · atoms and components | V | Icon button | Kind=Destructive, State=Focused | fd4390fc1eb2bae39ce589e3edd250000d21d0a1 |
| Discovery · atoms and components | V | Icon button | Kind=Destructive, State=Disabled | 550789ea7c2ccdba31aa3afe95cf9a951eb687e1 |
| Discovery · atoms and components | S | Inline note |  | 5c9c94d5443a2056e72fee412dd83a3fba7d50ba |
| Discovery · atoms and components | V | Inline note | Tone=Neutral | b8d9406be13833991a6708491fd20f99228b001d |
| Discovery · atoms and components | V | Inline note | Tone=Done | 5bd4ef99fd65223aebe77b079fb4fd034c796e8a |
| Discovery · atoms and components | V | Inline note | Tone=Attention | 0223087c44aca50d1e8568cf947b47f0483a9a80 |
| Discovery · atoms and components | V | Inline note | Tone=Error | 42e83eb32da702434a3daf2f9d8ead44c9bf9521 |
| Discovery · atoms and components | S | Secure field |  | 24bbb4a9cb79c3b3d8882bae372708cd424b66dc |
| Discovery · atoms and components | V | Secure field | State=Empty | 7dc98060a3ae09f4d01b9d6af04d9dc8e410c5d7 |
| Discovery · atoms and components | V | Secure field | State=Focused | f5abb30519787f18470ac0e792f4540475938a46 |
| Discovery · atoms and components | V | Secure field | State=Checking | ce0028d4ea4d4fda873448683fd008f96814156a |
| Discovery · atoms and components | V | Secure field | State=Accepted | 2c608463023ded9729d194ec6ae33a9cca444b3d |
| Discovery · atoms and components | V | Secure field | State=Not accepted | 8c964622c5e181d278ffd1641ea6daebeecf70c4 |
| Discovery · atoms and components | V | Secure field | State=Offline | c15ad723010e8560b586ac6b353b469237277782 |
| Discovery · atoms and components | V | Secure field | State=Shown | 0ed6b3f017dc0ddc1ead3e2b9f54c088e863d8ce |
| Discovery · atoms and components | V | Secure field | State=Not accepted (red) | a5135c10c2dd08fa2e1115a65616fed6c8703e71 |
| Discovery · atoms and components | S | Text area |  | d3e7e4d270c6491752905c5d2f2f13b97b0a66d9 |
| Discovery · atoms and components | V | Text area | State=Default | 4ba293334297cc32855ca15315ffcbbdc8a87ef3 |
| Discovery · atoms and components | V | Text area | State=Focused | ccdf1bd22c4565429b70e709c85f468e83cfcfac |
| Discovery · atoms and components | S | Shortcut recorder (version 1) |  | 595a6a33a24239f870852ad7108b32277a4b47e8 |
| Discovery · atoms and components | V | Shortcut recorder (version 1) | State=Recording | 87ea12251740f202e7616b1127c3a2026ee69f6f |
| Discovery · atoms and components | V | Shortcut recorder (version 1) | State=Set (one key) | 1ae4a82284b18bb1f51a313843a8e156eec008c3 |
| Discovery · atoms and components | V | Shortcut recorder (version 1) | State=Not allowed | af02bfa167f806810b327afe748fa471714e267a |
| Discovery · atoms and components | V | Shortcut recorder (version 1) | State=Not allowed (red) | e37f73888ee98e9c91cc34a99f753e4293e494b0 |
| Discovery · atoms and components | S | Status row (version 1) |  | 6905ce8ae677f8e10a0a8bd3391742d4d1886005 |
| Discovery · atoms and components | V | Status row (version 1) | State=Info | 59fd1d369a045172e891474713452e4060a41768 |
| Discovery · atoms and components | S | Status icon |  | 2f420e34f641eceacd738bbeb5b08a12fcdfb4d1 |
| Discovery · atoms and components | V | Status icon | State=Done | 51c70bd1e5a7073a48eb3543c6e1065e168193a8 |
| Discovery · atoms and components | V | Status icon | State=Attention | 1dd9eff495848122140a108612e9342427706d87 |
| Discovery · atoms and components | V | Status icon | State=Retry | 89af955884f8e9f44df1ee2f5d452ad4608210aa |
| Discovery · atoms and components | S | Settings row |  | 8d3f0c9d6ac6b1675bd378f5a79d84814ca924ab |
| Discovery · atoms and components | V | Settings row | Control=Toggle | 69734d5f4f53731ea3a4931388a78e3de072865c |
| Discovery · atoms and components | V | Settings row | Control=Pop-up | e97af2924ca1a6ec946de4ab5377dab288aaf50f |
| Discovery · atoms and components | V | Settings row | Control=Text field | 971ee7e472252810b2d1f6d47bcf093972aaefcf |
| Discovery · atoms and components | V | Settings row | Control=Shortcut recorder | 1e446ee53ec5883c7b8b4f93260c3106890f29fe |
| Discovery · atoms and components | V | Settings row | Control=Button | 076005f853f659602c17ea5c2605269bdee8f8da |
| Discovery · atoms and components | V | Settings row | Control=Status granted | f55ff94ec6ac8fb0771fe49d56179250ffaa9bf5 |
| Discovery · atoms and components | V | Settings row | Control=Status not granted | 17c817d74819f0f74cc25083d31400aa7da52f42 |
| Discovery · atoms and components | S | Permission row |  | bc620ef261bf0f1dd79a6a3d45cc8246a655e1a9 |
| Discovery · atoms and components | V | Permission row | Permission=Microphone, State=Not asked | e1ed59d04c24ef3dfbe10d5dc27a583ff9907fe4 |
| Discovery · atoms and components | V | Permission row | Permission=Microphone, State=Denied | 4216de799706cf2a6aac34c1700fec8592740953 |
| Discovery · atoms and components | V | Permission row | Permission=Microphone, State=Granted | 1fcc87244fc4fd5f3baec0e432fd696299818dcb |
| Discovery · atoms and components | V | Permission row | Permission=Accessibility, State=Not granted | 32a726ab7eeb2a8a3bb129d3947ad84dfbcaf5ba |
| Discovery · atoms and components | V | Permission row | Permission=Accessibility, State=Granted | 1c741f61539475d2c4ed0480b1c90a6c8e8e6679 |
| Discovery · atoms and components | V | Permission row | Permission=Microphone, State=Checking | ca1e9367433e39eea53a956b6445976d96249bac |
| Discovery · atoms and components | V | Permission row | Permission=Accessibility, State=Checking | 02b3cd661f717d1efcfefe856a46daeb9f572813 |
| Discovery · atoms and components | S | Popover empty history |  | f0d95fb078f67d15a4eee2747d994103adc86ab4 |
| Discovery · atoms and components | V | Popover empty history | Key=Set | 1e65725caa4e01647cc0f91fa96b25e80c64b0a1 |
| Discovery · atoms and components | V | Popover empty history | Key=Not set | e7879e2ba7200ea84f4f5cc85741b3ccbf317d0a |
| Discovery · atoms and components | S | Popover status row |  | 392696e5817133c58b1fc5767ba7f39099541447 |
| Discovery · atoms and components | V | Popover status row | Status=Ready | 19e85d0660a161d21ca5ba621653a9df2c7a371c |
| Discovery · atoms and components | V | Popover status row | Status=Listening hold | 258ee3205b01ab9148c7b5b27116696fc8616e83 |
| Discovery · atoms and components | V | Popover status row | Status=Listening hands-free | 6f5d088b45475691ac9eadaa7178ba2d55a3770f |
| Discovery · atoms and components | V | Popover status row | Status=Cleaning up | 7681df292676f811081aa3afba2d7a47d10cd33b |
| Discovery · atoms and components | V | Popover status row | Status=Mic warm | bc8d65ae6d7dec22aad63b258621bc7d4bda1890 |
| Discovery · atoms and components | V | Popover status row | Status=Cleanup off | 1ae19a2c688274e802904f63a74d7d1dfbafda76 |
| Discovery · atoms and components | V | Popover status row | Status=No key | 386d78c449647098a32b3807db9f19dc2034ca2d |
| Discovery · atoms and components | V | Popover status row | Status=Key not accepted | e8d7c3f036dd284dd3602e3f9dfeb9de6afa7827 |
| Discovery · atoms and components | V | Popover status row | Status=Offline | 3ca8551aa4bf9a4d3343cf9f44bf4bdcfaa0ff5f |
| Discovery · atoms and components | V | Popover status row | Status=Microphone off | f8c22399b5efae26f906fe0b391748a47a289118 |
| Discovery · atoms and components | V | Popover status row | Status=Accessibility off | 3af2036d74d86d3fe977aa7c262993ae3a276056 |
| Discovery · atoms and components | V | Popover status row | Status=Transcript waiting | 31bbc74eae74c89d489d8cd757019b78c98ad739 |
| Discovery · atoms and components | S | History row/Row click |  | a05dd7e70c456fa8026da17e5e3b7714e94e9cf5 |
| Discovery · atoms and components | V | History row/Row click | State=Default | 7b46a047e60c2f732b3fde29b1b1255664ef37b1 |
| Discovery · atoms and components | V | History row/Row click | State=Hover | ece93f3c7ba0f63f30fe5f254c11ecc671d061fa |
| Discovery · atoms and components | V | History row/Row click | State=Selected | 07f1291159f2306113ccf16a2cf143c0c7bf2844 |
| Discovery · atoms and components | V | History row/Row click | State=Focused | 71c511f5f8567a42a2137bab86e7a13d45ff2fd8 |
| Discovery · atoms and components | V | History row/Row click | State=Copied | ff1fa3935806371b0ce890817f2146ce43854e83 |
| Discovery · atoms and components | V | History row/Row click | State=Fallback | 74085cf57e9ab9431837ca850cf004663e414022 |
| Discovery · atoms and components | V | History row/Row click | State=Not pasted | 34131be3cf59939b5b292d1b787443352effccc6 |
| Discovery · atoms and components | V | History row/Row click | State=Pasted again | 2fd3e1de63b5fd9f139e3a4ac36f8c2cd55d3c1c |
| Discovery · atoms and components | V | History row/Row click | State=Paste again failed | 4a5292ea27cd3de9fefb258b6e647caa04e81896 |
| Discovery · atoms and components | S | Popover footer row |  | 603303315daa0d8857e8d8e9c5efe6256d2f82ee |
| Discovery · atoms and components | V | Popover footer row | State=Default | 990e4e20b64c50d1b7161e9cb8544b7f0d2bf942 |
| Discovery · atoms and components | V | Popover footer row | State=Hover | 7c3e52e9e78b8d5cd0147acf79b52d46cfa5353a |
| Discovery · atoms and components | V | Popover footer row | State=Focused | d4743bc01d7d27cb6200b3480b2b3afc9c421a4e |
| Discovery · atoms and components | S | History row/Hover buttons |  | f6f26f8c87b02ecb9e7594eb2444e9c9d06bf877 |
| Discovery · atoms and components | V | History row/Hover buttons | State=Default | 5fc409acf4c24d6623467c6e3eaee397cc6769b3 |
| Discovery · atoms and components | V | History row/Hover buttons | State=Hover | d6cd9b55a996cebe671e7919dc531617f456cac7 |
| Discovery · atoms and components | V | History row/Hover buttons | State=Selected | 4889e0c15f99cbdef6781a37faabe005b2fe6f54 |
| Discovery · atoms and components | V | History row/Hover buttons | State=Focused | 580a5b1b3dc49e414cd3eba47345b10df6be570a |
| Discovery · atoms and components | V | History row/Hover buttons | State=Copied | f405634c3ac1c668a4f26e12d560d43515cc7ed2 |
| Discovery · atoms and components | V | History row/Hover buttons | State=Fallback | cbf6eaf11d6bdc0256d1ccd2f0ea65a955362059 |
| Discovery · atoms and components | V | History row/Hover buttons | State=Not pasted | 9faf998fb9a2230b82dec2a238e65f1ed8384aba |
| Discovery · atoms and components | V | History row/Hover buttons | State=Pasted again | d952f1d1848cf57ecf21ddc42ed51d2fc4318ebd |
| Discovery · atoms and components | V | History row/Hover buttons | State=Paste again failed | d3b4987f7c6b32117220dd4b05d71101de67f552 |
| Discovery · atoms and components | S | Sidebar status line |  | 348af10cefb5735483de17fd00d11b8e4cc73a22 |
| Discovery · atoms and components | V | Sidebar status line | Status=Ready | 505e63d6fc6a3ab8f6146198c8c44353badbcc16 |
| Discovery · atoms and components | V | Sidebar status line | Status=Listening | db3914d381223c02b48ecc4d9e688c60815f9ea1 |
| Discovery · atoms and components | V | Sidebar status line | Status=Cleaning up | d63ff1659f8e3faa031e52f2f0a3c532e70d3fac |
| Discovery · atoms and components | V | Sidebar status line | Status=Mic warm | 1ca5ea85ffa0c131aea984d3a4f20c09ba803b7d |
| Discovery · atoms and components | V | Sidebar status line | Status=Cleanup off | 54d3b175bc92928cd2a493d1caa9fe45b8d7c28e |
| Discovery · atoms and components | V | Sidebar status line | Status=Transcript waiting | 3bb0223c1f0ebe5d9a1751f4b72aadb8cea9d810 |
| Discovery · atoms and components | V | Sidebar status line | Status=No dictation key | c5ed49781550c717ce0ff262f4f9e741719ce8be |
| Discovery · atoms and components | V | Sidebar status line | Status=Microphone off | ad96a262ff36703e0dd48c442f6b117ad0eb8f99 |
| Discovery · atoms and components | V | Sidebar status line | Status=Accessibility off | ded19957edbad88e722e72fd71857c575ed8ec27 |
| Discovery · atoms and components | V | Sidebar status line | Status=Accessibility off hover | a83a948c3287826d8338931b34eedd21040da915 |
| Discovery · atoms and components | V | Sidebar status line | Status=Accessibility off focused | 13338df91df41999f8f0165a8e918ef6cee176be |
| Discovery · atoms and components | V | Sidebar status line | Status=No key | 1a2f0f050e2788e7ea0bc7f614f70f66ffad05fa |
| Discovery · atoms and components | V | Sidebar status line | Status=Key not accepted | dd100f5a7823052eee70081921ccdf06be71cb7d |
| Discovery · atoms and components | V | Sidebar status line | Status=Offline | 099792259d8523729200860b3e2d3e44c8fc6f74 |
| Discovery · atoms and components | S | Shortcut row |  | 89f71bc9b38da9f42861b8db8aea1ddb8abb53cd |
| Discovery · atoms and components | V | Shortcut row | State=Idle | e20ed38d1e897b6d41b0d7d53feb45bd278cc016 |
| Discovery · atoms and components | V | Shortcut row | State=Recording | 08c66a05e3fff58df522e66fb9047f9aa359d846 |
| Discovery · atoms and components | V | Shortcut row | State=Set plain key | f9665074835085c3e78b90d65de0184bd5e03e92 |
| Discovery · atoms and components | V | Shortcut row | State=Set left Command | 315f1de6797648f2902bcac438f17df7db89f460 |
| Discovery · atoms and components | V | Shortcut row | State=Set right Option | 1bc93500645780c5fd1f4287be5d7b2789779f4f |
| Discovery · atoms and components | V | Shortcut row | State=Refused | 02f4b2cd919e59d393fe63f09c1a070e7810267d |
| Discovery · atoms and components | V | Shortcut row | State=Refused amber | ca05141e702ddb63322b8c42a88ec7e5720e9748 |
| Discovery · atoms and components | C | Tap and hold picture |  | 110c6a158b1e3beb1522dc5fdc6ec9c4a84defd9 |
| Discovery · atoms and components | S | Cleanup key row |  | ce240faf963173a65674f2ecdfcc86c8d8247891 |
| Discovery · atoms and components | V | Cleanup key row | State=No key | 2eec32562dd3636e00fbef93412af410f607f3b1 |
| Discovery · atoms and components | V | Cleanup key row | State=Focused | f7b005986da607f8dc74964658259c89192aa107 |
| Discovery · atoms and components | V | Cleanup key row | State=Checking | 72dce08b8e94bc54ae7a29fcc098146616f3a5e3 |
| Discovery · atoms and components | V | Cleanup key row | State=Accepted | a908657aeb40e03cd0709b17f8a36948a1508b1b |
| Discovery · atoms and components | V | Cleanup key row | State=Not accepted | 623e177f42d4f16ea50ea36b5e80cc4e5b17b030 |
| Discovery · atoms and components | V | Cleanup key row | State=Not accepted amber | e2e9cb5d11f4dec6a092395e7ea10cdbe6ee3bb7 |
| Discovery · atoms and components | V | Cleanup key row | State=Offline | a320cf014b0155cb81b718e1951365cfd8e53efd |
| Discovery · atoms and components | V | Cleanup key row | State=Shown | 9131abc3896ce34dd817ba64e270fdecd0a681c2 |
| Discovery · atoms and components | S | Cleanup rules |  | e33809b167fa92dee97abd426ad29c8ed66c2ac5 |
| Discovery · atoms and components | V | Cleanup rules | State=At default | 571340b790fffaed512c8faec324b77c0b10d4c1 |
| Discovery · atoms and components | V | Cleanup rules | State=Focused | b58bba0464c4fdb393e55f14280c15c53bfbd295 |
| Discovery · atoms and components | V | Cleanup rules | State=Edited | 01a3b1a682f5b52559b525eade98b9ad4a75947c |
| Discovery · atoms and components | V | Cleanup rules | State=Restored | 6a7a2a1d34cbb2dbb16ab2505b82a519d0e3a198 |
| Discovery · atoms and components | S | Word row |  | 5d37744ec99c9ef7ef0812c27e144fe2d81f08aa |
| Discovery · atoms and components | V | Word row | State=Default | 950598c7b83f8cc59903bc6c96dc50ea3f4d4b03 |
| Discovery · atoms and components | V | Word row | State=Hover | 41fde266d1149b82af31fd2e955fe9e3bc434e4b |
| Discovery · atoms and components | V | Word row | State=Selected | 1b3c9020f6b4ece6eca9752f46fdd4344274f822 |
| Discovery · atoms and components | V | Word row | State=Focused | 96d2d58e0a9f1de5cd46faaca56f7a370268e98d |
| Discovery · atoms and components | V | Word row | State=Editing | a13ffb6673a1ca8d0d768c512e19dfa6550bcc23 |
| Discovery · atoms and components | V | Word row | State=Duplicate | b3da8bf00441927c13882724ef7b0176b452cc8b |
| Discovery · atoms and components | C | Word list bar |  | e7378c47b4912034655c9ed1a95304395ac0e412 |
| Discovery · atoms and components | C | Word add row |  | 55eec69c352af7d25c89ac4ffbe81085032bfab7 |
| Discovery · atoms and components | C | Progress bar |  | 47e3a7262c12d45e7321a5a78797f682d6c9d5e1 |
| Discovery · atoms and components | S | Speech model row |  | becf17e6ca2dda90e7249ca347aebdc178b3af3f |
| Discovery · atoms and components | V | Speech model row | State=Downloading | cf23d64890819a5b5cc395e39018c01b21b31cee |
| Discovery · atoms and components | V | Speech model row | State=Loading | 21d6a01f18b572f4b1db8df6a012f6a6a635ebc0 |
| Discovery · atoms and components | V | Speech model row | State=Ready | e699af9955f5ad498ebe1131b4f5c794adf4fe6f |
| Discovery · atoms and components | V | Speech model row | State=Stopped | 73abb8f0f3f954c261d1c2e90799ee32d49fec5d |

## 3. Before screenshots

Saved in /private/tmp/claude-501/-Users-alechenderson-Projects-Fluidity--claude-worktrees-design-discovery-v1-screens-842bfb/eea079bf-f190-4547-9b1f-a8c565dc1090/scratchpad/relink/before/:
1. 2070:5485 Settings · General · key set to Right ⌥, tap and hold in two help lines (A)
2. 2064:3662 Popover · Ready with history
3. 2080:9163 First-run check · A: one window · nothing granted (the brief said "nothing allowed"; the frame says "nothing granted")
4. 2048:2541 Recording pill · Nowhere to paste · A
5. 2048:3222 Menu bar icon · Ready · options A, B, C
6. 2079:9071 Settings · sidebar status line · every status

## Inventory before relinking (Screens section 2048:1603)

Sub-sections: Recording pill 2048:1604, Menu bar icon 2048:3221, Popover 2064:3661, Settings 2070:5484, First-run check 2080:9162.

| Sub-section | Nodes walked (stop at instances) | Top-level instances, local main | Distinct components | Local styles in use | Frames with local Glass · Color mode |
|---|---|---|---|---|---|
| Recording pill | 663 | 58 | 12 | Glass/Section, Small, Label, Detail | 56 (28 Light, 28 Dark) |
| Menu bar icon | 715 | 60 | 15 | Glass/Section, Small, Label, Body, Detail | 60 |
| Popover | 1110 | 287 | 31 | Glass/Section, Small, Body, Label, Detail; Elevation/Float | 36 |
| Settings | 2097 | 655 | 51 | Glass/Section, Small, Title, Label, Detail; Elevation/Float | 64 |
| First-run check | 420 | 80 | 16 | Glass/Section, Small, Title, Body, Label, Detail; Elevation/Float | 16 |

Local variables in use: Glass · Color text/primary, text/secondary, surface/window, surface/sidebar, surface/selected, surface/raised, line/rule; Dimension radius/container (four corner radii). No instance has a remote main yet. Every used component name has a library match (no "could not relink" entries from the name match).

(Correction to the inventory table: top-level instance counts are the swap counts below; my hand sums in the table were off.)

## 4. Instance swaps (done)

Method: top-level instances only (no instance ancestor), main component local, matched by "set name | variant name" or component name to the key map, imported with Promise.all(importComponentByKeyAsync), then swapComponent.

| Sub-section | Swapped | Distinct library components | Could not relink |
|---|---|---|---|
| Recording pill 2048:1604 | 56 | 12 | none |
| Menu bar icon 2048:3221 | 60 | 15 | none |
| Popover 2064:3661 | 308 | 31 | none |
| Settings 2070:5484 | 596 | 51 | none |
| First-run check 2080:9162 | 80 | 16 | none |
| Total | 1100 | | none |

Check after the Recording pill swap: screenshot of 2048:2541 is byte-identical (same MD5) to the before image.

## 5. Variable, style and mode rebinds (done)

Walked every node outside instances, plus each top-level instance's own properties. Nothing unmapped, nothing left unhandled.

| Sub-section | Fill/stroke paints | Text colour ranges | Corner radius fields | Text style ranges | Effect styles | Light/Dark modes moved to library collection |
|---|---|---|---|---|---|---|
| Recording pill | 0 | 196 | 0 | 196 | 0 | 56 |
| Menu bar icon | 180 | 185 | 0 | 155 | 0 | 60 |
| Popover | 290 | 202 | 0 | 202 | 36 | 36 |
| Settings | 374 | 370 | 208 | 370 | 62 | 64 |
| First-run check | 82 | 100 | 0 | 100 | 14 | 16 |
| Total | 926 | 1053 | 208 | 1023 | 112 | 232 |

Library mode ids match the local ones (Light 2021:5, Dark 2021:6); matched by mode name anyway. After this step the 2048:2541 render is still byte-identical to the before image.

## 6. Verify

First pass: five of six after screenshots byte-identical; Settings General 2070:5485 differed. Its Dark pane lost the Cleanup, Words and Permissions sidebar icons. Cause: the Sidebar item instances carry an instance-swap choice for their Icon, and that choice survived the parent swap still pointing at the local Icon/Cleanup, Icon/Words, Icon/Permissions. Those local icons bind text/primary from the local collection, which fell back to Light once the pane's local mode was cleared.

Full-depth check (inside instances too) found this only in Settings: 200 nested instances with a local main (Icon/Cleanup 62, Icon/Words 62, Icon/Permissions 62, Toggle Off Enabled 4, Toggle Off Disabled 4, Text field Focused 2, Button Secondary Default 2, Icon button Quiet Default 2). Swapped each of them to the library component of the same name. Settings check after that: zero.

Final check, all depths, per sub-section (local main / nodes bound to a local variable or mode / nodes using a local style):
- Recording pill 945 nodes: 0 / 0 / 0
- Menu bar icon 959 nodes: 0 / 0 / 0
- Popover 3047 nodes: 0 / 0 / 0
- Settings 5367 nodes: 0 / 0 / 0
- First-run check 930 nodes: 0 / 0 / 0

Second pass screenshots: all six byte-identical (cmp) to the before set. Saved in .../scratchpad/relink/after/.

## 7. Deletes (done)

Each delete ran a reference check in the same script and only removed the item when the check came back clean (component.getInstancesAsync() for every component inside it, no instance outside; for variables and styles, a walk of all 11,249 nodes left on the page).
1. Discovery Components section 2048:1465 (99 components). Deleted before Atoms because Components used Atoms section components.
2. Discovery Atoms section 2044:238 (58 components).
3. Page Style Guide 2008:403 (0 components).
4. Page Tokens 2008:402 (0 components).
5. Page Atoms 2007:400 (49 components).
6. Page "Recording pill: Rim (approved)" 27:2 (30 components).
7. Local variable collections: Rim (53), Color (superseded by Glass) (22), Dimension (27), Motion (17), Type (10), Glass · Color (18).
8. Local text styles Record/* (9) and Glass/* (7); effect style Elevation/Float. No paint or grid styles existed.

Nothing needed keeping, so no "Local, to relink" section was made.

## 8. Rename and note

- File rename: NOT done. figma.root.name refused with "Setting the document name is currently not supported". Alec renames it to "Fluidity -- Screens" by hand.
- Page 2044:237 renamed "Screens · version 1 discovery". It is the only page.
- Note text 4021:10300 "Note · screens file", Inter Regular 16/24, 720 wide, at x 4400, y -120 (above the Screens section's left edge; the page has nothing further left).
- Screens section 2048:1603 at x 4400, y 0, with sub-sections Recording pill 2048:1604, Menu bar icon 2048:3221, Popover 2064:3661, Settings 2070:5484, First-run check 2080:9162.
- Final overview: .../scratchpad/relink/final-page-overview.png

## Progress (final)

Steps 1 to 7 done. Step 8 done apart from the file rename.
