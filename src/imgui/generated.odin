package imgui

import "core:c"
import "core:math"

// ImGuiComboFlags
ImGuiComboFlags :: enum c.int {
	None = 0,
	PopupAlignLeft = 1,
	HeightSmall = 2,
	HeightRegular = 4,
	HeightLarge = 8,
	HeightLargest = 16,
	NoArrowButton = 32,
	NoPreview = 64,
	WidthFitPreview = 128,
	HeightMask_ = 30,
}

// ImGuiSortDirection
ImGuiSortDirection :: enum c.int {
	None = 0,
	Ascending = 1,
	Descending = 2,
}

// ImGuiDockNodeFlags
ImGuiDockNodeFlags :: enum c.int {
	None = 0,
	KeepAliveOnly = 1,
	NoDockingOverCentralNode = 4,
	PassthruCentralNode = 8,
	NoDockingSplit = 16,
	NoResize = 32,
	AutoHideTabBar = 64,
	NoUndocking = 128,
}

// ImGuiDragDropFlags
ImGuiDragDropFlags :: enum c.int {
	None = 0,
	SourceNoPreviewTooltip = 1,
	SourceNoDisableHover = 2,
	SourceNoHoldToOpenOthers = 4,
	SourceAllowNullID = 8,
	SourceExtern = 16,
	PayloadAutoExpire = 32,
	PayloadNoCrossContext = 64,
	PayloadNoCrossProcess = 128,
	AcceptBeforeDelivery = 1024,
	AcceptNoDrawDefaultRect = 2048,
	AcceptNoPreviewTooltip = 4096,
	AcceptPeekOnly = 3072,
}

// ImGuiTableColumnFlags
ImGuiTableColumnFlags :: enum c.int {
	None = 0,
	Disabled = 1,
	DefaultHide = 2,
	DefaultSort = 4,
	WidthStretch = 8,
	WidthFixed = 16,
	NoResize = 32,
	NoReorder = 64,
	NoHide = 128,
	NoClip = 256,
	NoSort = 512,
	NoSortAscending = 1024,
	NoSortDescending = 2048,
	NoHeaderLabel = 4096,
	NoHeaderWidth = 8192,
	PreferSortAscending = 16384,
	PreferSortDescending = 32768,
	IndentEnable = 65536,
	IndentDisable = 131072,
	AngledHeader = 262144,
	IsEnabled = 16777216,
	IsVisible = 33554432,
	IsSorted = 67108864,
	IsHovered = 134217728,
	WidthMask_ = 24,
	IndentMask_ = 196608,
	StatusMask_ = 251658240,
	NoDirectResize_ = 1073741824,
}

// ImGuiTableRowFlags
ImGuiTableRowFlags :: enum c.int {
	None = 0,
	Headers = 1,
}

// ImGuiWindowFlags
ImGuiWindowFlags :: enum c.int {
	None = 0,
	NoTitleBar = 1,
	NoResize = 2,
	NoMove = 4,
	NoScrollbar = 8,
	NoScrollWithMouse = 16,
	NoCollapse = 32,
	AlwaysAutoResize = 64,
	NoBackground = 128,
	NoSavedSettings = 256,
	NoMouseInputs = 512,
	MenuBar = 1024,
	HorizontalScrollbar = 2048,
	NoFocusOnAppearing = 4096,
	NoBringToFrontOnFocus = 8192,
	AlwaysVerticalScrollbar = 16384,
	AlwaysHorizontalScrollbar = 32768,
	NoNavInputs = 65536,
	NoNavFocus = 131072,
	UnsavedDocument = 262144,
	NoDocking = 524288,
	NoNav = 196608,
	NoDecoration = 43,
	NoInputs = 197120,
	ChildWindow = 16777216,
	Tooltip = 33554432,
	Popup = 67108864,
	Modal = 134217728,
	ChildMenu = 268435456,
	DockNodeHost = 536870912,
}

// ImGuiDir
ImGuiDir :: enum c.int {
	None = -1,
	Left = 0,
	Right = 1,
	Up = 2,
	Down = 3,
}

// ImGuiHoveredFlags
ImGuiHoveredFlags :: enum c.int {
	None = 0,
	ChildWindows = 1,
	RootWindow = 2,
	AnyWindow = 4,
	NoPopupHierarchy = 8,
	DockHierarchy = 16,
	AllowWhenBlockedByPopup = 32,
	AllowWhenBlockedByActiveItem = 128,
	AllowWhenOverlappedByItem = 256,
	AllowWhenOverlappedByWindow = 512,
	AllowWhenDisabled = 1024,
	NoNavOverride = 2048,
	AllowWhenOverlapped = 768,
	RectOnly = 928,
	RootAndChildWindows = 3,
	ForTooltip = 4096,
	Stationary = 8192,
	DelayNone = 16384,
	DelayShort = 32768,
	DelayNormal = 65536,
	NoSharedDelay = 131072,
}

// ImGuiCol
ImGuiCol :: enum c.int {
	Text = 0,
	TextDisabled = 1,
	WindowBg = 2,
	ChildBg = 3,
	PopupBg = 4,
	Border = 5,
	BorderShadow = 6,
	FrameBg = 7,
	FrameBgHovered = 8,
	FrameBgActive = 9,
	TitleBg = 10,
	TitleBgActive = 11,
	TitleBgCollapsed = 12,
	MenuBarBg = 13,
	ScrollbarBg = 14,
	ScrollbarGrab = 15,
	ScrollbarGrabHovered = 16,
	ScrollbarGrabActive = 17,
	CheckMark = 18,
	SliderGrab = 19,
	SliderGrabActive = 20,
	Button = 21,
	ButtonHovered = 22,
	ButtonActive = 23,
	Header = 24,
	HeaderHovered = 25,
	HeaderActive = 26,
	Separator = 27,
	SeparatorHovered = 28,
	SeparatorActive = 29,
	ResizeGrip = 30,
	ResizeGripHovered = 31,
	ResizeGripActive = 32,
	TabHovered = 33,
	Tab = 34,
	TabSelected = 35,
	TabSelectedOverline = 36,
	TabDimmed = 37,
	TabDimmedSelected = 38,
	TabDimmedSelectedOverline = 39,
	DockingPreview = 40,
	DockingEmptyBg = 41,
	PlotLines = 42,
	PlotLinesHovered = 43,
	PlotHistogram = 44,
	PlotHistogramHovered = 45,
	TableHeaderBg = 46,
	TableBorderStrong = 47,
	TableBorderLight = 48,
	TableRowBg = 49,
	TableRowBgAlt = 50,
	TextSelectedBg = 51,
	DragDropTarget = 52,
	NavHighlight = 53,
	NavWindowingHighlight = 54,
	NavWindowingDimBg = 55,
	ModalWindowDimBg = 56,
}

// ImGuiTabBarFlags
ImGuiTabBarFlags :: enum c.int {
	None = 0,
	Reorderable = 1,
	AutoSelectNewTabs = 2,
	TabListPopupButton = 4,
	NoCloseWithMiddleMouseButton = 8,
	NoTabListScrollingButtons = 16,
	NoTooltip = 32,
	DrawSelectedOverline = 64,
	FittingPolicyResizeDown = 128,
	FittingPolicyScroll = 256,
	FittingPolicyMask_ = 384,
	FittingPolicyDefault_ = 128,
}

// ImGuiViewportFlags
ImGuiViewportFlags :: enum c.int {
	None = 0,
	IsPlatformWindow = 1,
	IsPlatformMonitor = 2,
	OwnedByApp = 4,
	NoDecoration = 8,
	NoTaskBarIcon = 16,
	NoFocusOnAppearing = 32,
	NoFocusOnClick = 64,
	NoInputs = 128,
	NoRendererClear = 256,
	NoAutoMerge = 512,
	TopMost = 1024,
	CanHostOtherWindows = 2048,
	IsMinimized = 4096,
	IsFocused = 8192,
}

// ImGuiInputTextFlags
ImGuiInputTextFlags :: enum c.int {
	None = 0,
	CharsDecimal = 1,
	CharsHexadecimal = 2,
	CharsScientific = 4,
	CharsUppercase = 8,
	CharsNoBlank = 16,
	AllowTabInput = 32,
	EnterReturnsTrue = 64,
	EscapeClearsAll = 128,
	CtrlEnterForNewLine = 256,
	ReadOnly = 512,
	Password = 1024,
	AlwaysOverwrite = 2048,
	AutoSelectAll = 4096,
	ParseEmptyRefVal = 8192,
	DisplayEmptyRefVal = 16384,
	NoHorizontalScroll = 32768,
	NoUndoRedo = 65536,
	CallbackCompletion = 131072,
	CallbackHistory = 262144,
	CallbackAlways = 524288,
	CallbackCharFilter = 1048576,
	CallbackResize = 2097152,
	CallbackEdit = 4194304,
}

// ImGuiCond
ImGuiCond :: enum c.int {
	None = 0,
	Always = 1,
	Once = 2,
	FirstUseEver = 4,
	Appearing = 8,
}

// ImDrawFlags
ImDrawFlags :: enum c.int {
	None = 0,
	Closed = 1,
	RoundCornersTopLeft = 16,
	RoundCornersTopRight = 32,
	RoundCornersBottomLeft = 64,
	RoundCornersBottomRight = 128,
	RoundCornersNone = 256,
	RoundCornersTop = 48,
	RoundCornersBottom = 192,
	RoundCornersLeft = 80,
	RoundCornersRight = 160,
	RoundCornersAll = 240,
	RoundCornersDefault_ = 240,
	RoundCornersMask_ = 496,
}

// ImGuiButtonFlags
ImGuiButtonFlags :: enum c.int {
	None = 0,
	MouseButtonLeft = 1,
	MouseButtonRight = 2,
	MouseButtonMiddle = 4,
	MouseButtonMask_ = 7,
}

// ImGuiKey
ImGuiKey :: enum c.int {
	None = 0,
	Tab = 512,
	LeftArrow = 513,
	RightArrow = 514,
	UpArrow = 515,
	DownArrow = 516,
	PageUp = 517,
	PageDown = 518,
	Home = 519,
	End = 520,
	Insert = 521,
	Delete = 522,
	Backspace = 523,
	Space = 524,
	Enter = 525,
	Escape = 526,
	LeftCtrl = 527,
	LeftShift = 528,
	LeftAlt = 529,
	LeftSuper = 530,
	RightCtrl = 531,
	RightShift = 532,
	RightAlt = 533,
	RightSuper = 534,
	Menu = 535,
	_0 = 536,
	_1 = 537,
	_2 = 538,
	_3 = 539,
	_4 = 540,
	_5 = 541,
	_6 = 542,
	_7 = 543,
	_8 = 544,
	_9 = 545,
	A = 546,
	B = 547,
	C = 548,
	D = 549,
	E = 550,
	F = 551,
	G = 552,
	H = 553,
	I = 554,
	J = 555,
	K = 556,
	L = 557,
	M = 558,
	N = 559,
	O = 560,
	P = 561,
	Q = 562,
	R = 563,
	S = 564,
	T = 565,
	U = 566,
	V = 567,
	W = 568,
	X = 569,
	Y = 570,
	Z = 571,
	F1 = 572,
	F2 = 573,
	F3 = 574,
	F4 = 575,
	F5 = 576,
	F6 = 577,
	F7 = 578,
	F8 = 579,
	F9 = 580,
	F10 = 581,
	F11 = 582,
	F12 = 583,
	F13 = 584,
	F14 = 585,
	F15 = 586,
	F16 = 587,
	F17 = 588,
	F18 = 589,
	F19 = 590,
	F20 = 591,
	F21 = 592,
	F22 = 593,
	F23 = 594,
	F24 = 595,
	Apostrophe = 596,
	Comma = 597,
	Minus = 598,
	Period = 599,
	Slash = 600,
	Semicolon = 601,
	Equal = 602,
	LeftBracket = 603,
	Backslash = 604,
	RightBracket = 605,
	GraveAccent = 606,
	CapsLock = 607,
	ScrollLock = 608,
	NumLock = 609,
	PrintScreen = 610,
	Pause = 611,
	Keypad0 = 612,
	Keypad1 = 613,
	Keypad2 = 614,
	Keypad3 = 615,
	Keypad4 = 616,
	Keypad5 = 617,
	Keypad6 = 618,
	Keypad7 = 619,
	Keypad8 = 620,
	Keypad9 = 621,
	KeypadDecimal = 622,
	KeypadDivide = 623,
	KeypadMultiply = 624,
	KeypadSubtract = 625,
	KeypadAdd = 626,
	KeypadEnter = 627,
	KeypadEqual = 628,
	AppBack = 629,
	AppForward = 630,
	GamepadStart = 631,
	GamepadBack = 632,
	GamepadFaceLeft = 633,
	GamepadFaceRight = 634,
	GamepadFaceUp = 635,
	GamepadFaceDown = 636,
	GamepadDpadLeft = 637,
	GamepadDpadRight = 638,
	GamepadDpadUp = 639,
	GamepadDpadDown = 640,
	GamepadL1 = 641,
	GamepadR1 = 642,
	GamepadL2 = 643,
	GamepadR2 = 644,
	GamepadL3 = 645,
	GamepadR3 = 646,
	GamepadLStickLeft = 647,
	GamepadLStickRight = 648,
	GamepadLStickUp = 649,
	GamepadLStickDown = 650,
	GamepadRStickLeft = 651,
	GamepadRStickRight = 652,
	GamepadRStickUp = 653,
	GamepadRStickDown = 654,
	MouseLeft = 655,
	MouseRight = 656,
	MouseMiddle = 657,
	MouseX1 = 658,
	MouseX2 = 659,
	MouseWheelX = 660,
	MouseWheelY = 661,
	ReservedForModCtrl = 662,
	ReservedForModShift = 663,
	ReservedForModAlt = 664,
	ReservedForModSuper = 665,
}

// ImGuiMouseSource
ImGuiMouseSource :: enum c.int {
	Mouse = 0,
	TouchScreen = 1,
	Pen = 2,
}

// ImGuiChildFlags
ImGuiChildFlags :: enum c.int {
	None = 0,
	Border = 1,
	AlwaysUseWindowPadding = 2,
	ResizeX = 4,
	ResizeY = 8,
	AutoResizeX = 16,
	AutoResizeY = 32,
	AlwaysAutoResize = 64,
	FrameStyle = 128,
	NavFlattened = 256,
}

// ImGuiDataType
ImGuiDataType :: enum c.int {
	S8 = 0,
	U8 = 1,
	S16 = 2,
	U16 = 3,
	S32 = 4,
	U32 = 5,
	S64 = 6,
	U64 = 7,
	Float = 8,
	Double = 9,
}

// ImGuiInputFlags
ImGuiInputFlags :: enum c.int {
	None = 0,
	Repeat = 1,
	RouteActive = 1024,
	RouteFocused = 2048,
	RouteGlobal = 4096,
	RouteAlways = 8192,
	RouteOverFocused = 16384,
	RouteOverActive = 32768,
	RouteUnlessBgFocused = 65536,
	RouteFromRootWindow = 131072,
	Tooltip = 262144,
}

// ImGuiTableFlags
ImGuiTableFlags :: enum c.int {
	None = 0,
	Resizable = 1,
	Reorderable = 2,
	Hideable = 4,
	Sortable = 8,
	NoSavedSettings = 16,
	ContextMenuInBody = 32,
	RowBg = 64,
	BordersInnerH = 128,
	BordersOuterH = 256,
	BordersInnerV = 512,
	BordersOuterV = 1024,
	BordersH = 384,
	BordersV = 1536,
	BordersInner = 640,
	BordersOuter = 1280,
	Borders = 1920,
	NoBordersInBody = 2048,
	NoBordersInBodyUntilResize = 4096,
	SizingFixedFit = 8192,
	SizingFixedSame = 16384,
	SizingStretchProp = 24576,
	SizingStretchSame = 32768,
	NoHostExtendX = 65536,
	NoHostExtendY = 131072,
	NoKeepColumnsVisible = 262144,
	PreciseWidths = 524288,
	NoClip = 1048576,
	PadOuterX = 2097152,
	NoPadOuterX = 4194304,
	NoPadInnerX = 8388608,
	ScrollX = 16777216,
	ScrollY = 33554432,
	SortMulti = 67108864,
	SortTristate = 134217728,
	HighlightHoveredColumn = 268435456,
	SizingMask_ = 57344,
}

// ImGuiMouseButton
ImGuiMouseButton :: enum c.int {
	Left = 0,
	Right = 1,
	Middle = 2,
}

// ImGuiPopupFlags
ImGuiPopupFlags :: enum c.int {
	None = 0,
	MouseButtonLeft = 0,
	MouseButtonRight = 1,
	MouseButtonMiddle = 2,
	MouseButtonMask_ = 31,
	MouseButtonDefault_ = 1,
	NoReopen = 32,
	NoOpenOverExistingPopup = 128,
	NoOpenOverItems = 256,
	AnyPopupId = 1024,
	AnyPopupLevel = 2048,
	AnyPopup = 3072,
}

// ImGuiConfigFlags
ImGuiConfigFlags :: enum c.int {
	None = 0,
	NavEnableKeyboard = 1,
	NavEnableGamepad = 2,
	NavEnableSetMousePos = 4,
	NavNoCaptureKeyboard = 8,
	NoMouse = 16,
	NoMouseCursorChange = 32,
	NoKeyboard = 64,
	DockingEnable = 128,
	ViewportsEnable = 1024,
	DpiEnableScaleViewports = 16384,
	DpiEnableScaleFonts = 32768,
	IsSRGB = 1048576,
	IsTouchScreen = 2097152,
}

// ImGuiStyleVar
ImGuiStyleVar :: enum c.int {
	Alpha = 0,
	DisabledAlpha = 1,
	WindowPadding = 2,
	WindowRounding = 3,
	WindowBorderSize = 4,
	WindowMinSize = 5,
	WindowTitleAlign = 6,
	ChildRounding = 7,
	ChildBorderSize = 8,
	PopupRounding = 9,
	PopupBorderSize = 10,
	FramePadding = 11,
	FrameRounding = 12,
	FrameBorderSize = 13,
	ItemSpacing = 14,
	ItemInnerSpacing = 15,
	IndentSpacing = 16,
	CellPadding = 17,
	ScrollbarSize = 18,
	ScrollbarRounding = 19,
	GrabMinSize = 20,
	GrabRounding = 21,
	TabRounding = 22,
	TabBorderSize = 23,
	TabBarBorderSize = 24,
	TableAngledHeadersAngle = 25,
	TableAngledHeadersTextAlign = 26,
	ButtonTextAlign = 27,
	SelectableTextAlign = 28,
	SeparatorTextBorderSize = 29,
	SeparatorTextAlign = 30,
	SeparatorTextPadding = 31,
	DockingSeparatorSize = 32,
}

// ImGuiBackendFlags
ImGuiBackendFlags :: enum c.int {
	None = 0,
	HasGamepad = 1,
	HasMouseCursors = 2,
	HasSetMousePos = 4,
	RendererHasVtxOffset = 8,
	PlatformHasViewports = 1024,
	HasMouseHoveredViewport = 2048,
	RendererHasViewports = 4096,
}

// ImGuiMouseCursor
ImGuiMouseCursor :: enum c.int {
	None = -1,
	Arrow = 0,
	TextInput = 1,
	ResizeAll = 2,
	ResizeNS = 3,
	ResizeEW = 4,
	ResizeNESW = 5,
	ResizeNWSE = 6,
	Hand = 7,
	NotAllowed = 8,
}

// ImFontAtlasFlags
ImFontAtlasFlags :: enum c.int {
	None = 0,
	NoPowerOfTwoHeight = 1,
	NoMouseCursors = 2,
	NoBakedLines = 4,
}

// ImGuiTabItemFlags
ImGuiTabItemFlags :: enum c.int {
	None = 0,
	UnsavedDocument = 1,
	SetSelected = 2,
	NoCloseWithMiddleMouseButton = 4,
	NoPushId = 8,
	NoTooltip = 16,
	NoReorder = 32,
	Leading = 64,
	Trailing = 128,
	NoAssumedClosure = 256,
}

// ImGuiSliderFlags
ImGuiSliderFlags :: enum c.int {
	None = 0,
	AlwaysClamp = 16,
	Logarithmic = 32,
	NoRoundToFormat = 64,
	NoInput = 128,
	WrapAround = 256,
	InvalidMask_ = 1879048207,
}

// ImGuiColorEditFlags
ImGuiColorEditFlags :: enum c.int {
	None = 0,
	NoAlpha = 2,
	NoPicker = 4,
	NoOptions = 8,
	NoSmallPreview = 16,
	NoInputs = 32,
	NoTooltip = 64,
	NoLabel = 128,
	NoSidePreview = 256,
	NoDragDrop = 512,
	NoBorder = 1024,
	AlphaBar = 65536,
	AlphaPreview = 131072,
	AlphaPreviewHalf = 262144,
	HDR = 524288,
	DisplayRGB = 1048576,
	DisplayHSV = 2097152,
	DisplayHex = 4194304,
	Uint8 = 8388608,
	Float = 16777216,
	PickerHueBar = 33554432,
	PickerHueWheel = 67108864,
	InputRGB = 134217728,
	InputHSV = 268435456,
	DefaultOptions_ = 177209344,
	DisplayMask_ = 7340032,
	DataTypeMask_ = 25165824,
	PickerMask_ = 100663296,
	InputMask_ = 402653184,
}

// ImGuiSelectableFlags
ImGuiSelectableFlags :: enum c.int {
	None = 0,
	DontClosePopups = 1,
	SpanAllColumns = 2,
	AllowDoubleClick = 4,
	Disabled = 8,
	AllowOverlap = 16,
}

// ImGuiFocusedFlags
ImGuiFocusedFlags :: enum c.int {
	None = 0,
	ChildWindows = 1,
	RootWindow = 2,
	AnyWindow = 4,
	NoPopupHierarchy = 8,
	DockHierarchy = 16,
	RootAndChildWindows = 3,
}

// ImDrawListFlags
ImDrawListFlags :: enum c.int {
	None = 0,
	AntiAliasedLines = 1,
	AntiAliasedLinesUseTex = 2,
	AntiAliasedFill = 4,
	AllowVtxOffset = 8,
}

// ImGuiTreeNodeFlags
ImGuiTreeNodeFlags :: enum c.int {
	None = 0,
	Selected = 1,
	Framed = 2,
	AllowOverlap = 4,
	NoTreePushOnOpen = 8,
	NoAutoOpenOnLog = 16,
	DefaultOpen = 32,
	OpenOnDoubleClick = 64,
	OpenOnArrow = 128,
	Leaf = 256,
	Bullet = 512,
	FramePadding = 1024,
	SpanAvailWidth = 2048,
	SpanFullWidth = 4096,
	SpanTextWidth = 8192,
	SpanAllColumns = 16384,
	NavLeftJumpsBackHere = 32768,
	CollapsingHeader = 26,
}

// ImGuiTableBgTarget
ImGuiTableBgTarget :: enum c.int {
	None = 0,
	RowBg0 = 1,
	RowBg1 = 2,
	CellBg = 3,
}

// ImFont
ImFont :: struct {
	IndexAdvanceX : ImVector(f32),
	FallbackAdvanceX : f32,
	FontSize : f32,
	IndexLookup : ImVector(ImWchar),
	Glyphs : ImVector(ImFontGlyph),
	FallbackGlyph : ^ImFontGlyph,
	ContainerAtlas : ^ImFontAtlas,
	ConfigData : ^ImFontConfig,
	ConfigDataCount : i16,
	FallbackChar : ImWchar,
	EllipsisChar : ImWchar,
	EllipsisCharCount : i16,
	EllipsisWidth : f32,
	EllipsisCharStep : f32,
	DirtyLookupTables : b8,
	Scale : f32,
	Ascent : f32,
	Descent : f32,
	MetricsTotalSurface : i32,
	Used4kPagesMap : [2]ImU8,
}

// ImVec4
ImVec4 :: struct {
	x : f32,
	y : f32,
	z : f32,
	w : f32,
}

// ImDrawChannel
ImDrawChannel :: struct {
	_CmdBuffer : ImVector(ImDrawCmd),
	_IdxBuffer : ImVector(ImDrawIdx),
}

// ImGuiTextRange
ImGuiTextRange :: struct {
	b : cstring,
	e : cstring,
}

// ImFontGlyph
ImFontGlyph :: struct {
	Colored : u32,
	Visible : u32,
	Codepoint : u32,
	AdvanceX : f32,
	X0 : f32,
	Y0 : f32,
	X1 : f32,
	Y1 : f32,
	U0 : f32,
	V0 : f32,
	U1 : f32,
	V1 : f32,
}

// ImDrawVert
ImDrawVert :: struct {
	pos : ImVec2,
	uv : ImVec2,
	col : ImU32,
}

// ImFontConfig
ImFontConfig :: struct {
	FontData : rawptr,
	FontDataSize : i32,
	FontDataOwnedByAtlas : b8,
	FontNo : i32,
	SizePixels : f32,
	OversampleH : i32,
	OversampleV : i32,
	PixelSnapH : b8,
	GlyphExtraSpacing : ImVec2,
	GlyphOffset : ImVec2,
	GlyphRanges : ^ImWchar,
	GlyphMinAdvanceX : f32,
	GlyphMaxAdvanceX : f32,
	MergeMode : b8,
	FontBuilderFlags : u32,
	RasterizerMultiply : f32,
	RasterizerDensity : f32,
	EllipsisChar : ImWchar,
	Name : [40]u8,
	DstFont : ^ImFont,
}

// ImGuiPlatformMonitor
ImGuiPlatformMonitor :: struct {
	MainPos : ImVec2,
	MainSize : ImVec2,
	WorkPos : ImVec2,
	WorkSize : ImVec2,
	DpiScale : f32,
	PlatformHandle : rawptr,
}

// StbUndoState
StbUndoState :: struct {
	undo_rec : [99]StbUndoRecord,
	undo_char : [999]ImWchar,
	undo_point : i16,
	redo_point : i16,
	undo_char_point : i32,
	redo_char_point : i32,
}

// STB_TexteditState
STB_TexteditState :: struct {
	cursor : i32,
	select_start : i32,
	select_end : i32,
	insert_mode : u8,
	row_count_per_page : i32,
	cursor_at_end_of_line : u8,
	initialized : u8,
	has_preferred_x : u8,
	single_line : u8,
	padding1 : u8,
	padding2 : u8,
	padding3 : u8,
	preferred_x : f32,
	undostate : StbUndoState,
}

// ImFontAtlas
ImFontAtlas :: struct {
	Flags : ImFontAtlasFlags,
	TexID : ImTextureID,
	TexDesiredWidth : i32,
	TexGlyphPadding : i32,
	Locked : b8,
	UserData : rawptr,
	TexReady : b8,
	TexPixelsUseColors : b8,
	TexPixelsAlpha8 : ^u8,
	TexPixelsRGBA32 : ^u32,
	TexWidth : i32,
	TexHeight : i32,
	TexUvScale : ImVec2,
	TexUvWhitePixel : ImVec2,
	Fonts : ImVector(^ImFont),
	CustomRects : ImVector(ImFontAtlasCustomRect),
	ConfigData : ImVector(ImFontConfig),
	TexUvLines : [64]ImVec4,
	FontBuilderIO : ^ImFontBuilderIO,
	FontBuilderFlags : u32,
	PackIdMouseCursors : i32,
	PackIdLines : i32,
}

// ImGuiTextFilter
ImGuiTextFilter :: struct {
	InputBuf : [256]u8,
	Filters : ImVector(ImGuiTextRange),
	CountGrep : i32,
}

// StbTexteditRow
StbTexteditRow :: struct {
	x0 : f32,
	x1 : f32,
	baseline_y_delta : f32,
	ymin : f32,
	ymax : f32,
	num_chars : i32,
}

// ImDrawList
ImDrawList :: struct {
	CmdBuffer : ImVector(ImDrawCmd),
	IdxBuffer : ImVector(ImDrawIdx),
	VtxBuffer : ImVector(ImDrawVert),
	Flags : ImDrawListFlags,
	_VtxCurrentIdx : u32,
	_Data : ^ImDrawListSharedData,
	_VtxWritePtr : ^ImDrawVert,
	_IdxWritePtr : ^ImDrawIdx,
	_Path : ImVector(ImVec2),
	_CmdHeader : ImDrawCmdHeader,
	_Splitter : ImDrawListSplitter,
	_ClipRectStack : ImVector(ImVec4),
	_TextureIdStack : ImVector(ImTextureID),
	_FringeScale : f32,
	_OwnerName : cstring,
}

// ImDrawCmd
ImDrawCmd :: struct {
	ClipRect : ImVec4,
	TextureId : ImTextureID,
	VtxOffset : u32,
	IdxOffset : u32,
	ElemCount : u32,
	UserCallback : ImDrawCallback,
	UserCallbackData : rawptr,
}

// ImGuiTableSortSpecs
ImGuiTableSortSpecs :: struct {
	Specs : ^ImGuiTableColumnSortSpecs,
	SpecsCount : i32,
	SpecsDirty : b8,
}

// ImVec2
ImVec2 :: struct {
	x : f32,
	y : f32,
}

// StbUndoRecord
StbUndoRecord :: struct {
	where_ : i32,
	insert_length : i32,
	delete_length : i32,
	char_storage : i32,
}

// ImGuiPayload
ImGuiPayload :: struct {
	Data : rawptr,
	DataSize : i32,
	SourceId : ImGuiID,
	SourceParentId : ImGuiID,
	DataFrameCount : i32,
	DataType : [33]u8,
	Preview : b8,
	Delivery : b8,
}

// ImColor
ImColor :: struct {
	Value : ImVec4,
}

// ImFontAtlasCustomRect
ImFontAtlasCustomRect :: struct {
	Width : u16,
	Height : u16,
	X : u16,
	Y : u16,
	GlyphID : u32,
	GlyphAdvanceX : f32,
	GlyphOffset : ImVec2,
	Font : ^ImFont,
}

// ImGuiKeyData
ImGuiKeyData :: struct {
	Down : b8,
	DownDuration : f32,
	DownDurationPrev : f32,
	AnalogValue : f32,
}

// ImGuiInputTextCallbackData
ImGuiInputTextCallbackData :: struct {
	Ctx : ^ImGuiContext,
	EventFlag : ImGuiInputTextFlags,
	Flags : ImGuiInputTextFlags,
	UserData : rawptr,
	EventChar : ImWchar,
	EventKey : ImGuiKey,
	Buf : cstring,
	BufTextLen : i32,
	BufSize : i32,
	BufDirty : b8,
	CursorPos : i32,
	SelectionStart : i32,
	SelectionEnd : i32,
}

// ImGuiSizeCallbackData
ImGuiSizeCallbackData :: struct {
	UserData : rawptr,
	Pos : ImVec2,
	CurrentSize : ImVec2,
	DesiredSize : ImVec2,
}

// ImGuiStorage
ImGuiStorage :: struct {
	Data : ImVector(ImGuiStoragePair),
}

// ImGuiPlatformIO
ImGuiPlatformIO :: struct {
	Platform_CreateWindow : rawptr,
	Platform_DestroyWindow : rawptr,
	Platform_ShowWindow : rawptr,
	Platform_SetWindowPos : rawptr,
	Platform_GetWindowPos : rawptr,
	Platform_SetWindowSize : rawptr,
	Platform_GetWindowSize : rawptr,
	Platform_SetWindowFocus : rawptr,
	Platform_GetWindowFocus : rawptr,
	Platform_GetWindowMinimized : rawptr,
	Platform_SetWindowTitle : rawptr,
	Platform_SetWindowAlpha : rawptr,
	Platform_UpdateWindow : rawptr,
	Platform_RenderWindow : rawptr,
	Platform_SwapBuffers : rawptr,
	Platform_GetWindowDpiScale : rawptr,
	Platform_OnChangedViewport : rawptr,
	Platform_CreateVkSurface : rawptr,
	Renderer_CreateWindow : rawptr,
	Renderer_DestroyWindow : rawptr,
	Renderer_SetWindowSize : rawptr,
	Renderer_RenderWindow : rawptr,
	Renderer_SwapBuffers : rawptr,
	Monitors : ImVector(ImGuiPlatformMonitor),
	Viewports : ImVector(^ImGuiViewport),
}

// ImDrawCmdHeader
ImDrawCmdHeader :: struct {
	ClipRect : ImVec4,
	TextureId : ImTextureID,
	VtxOffset : u32,
}

// ImGuiTextBuffer
ImGuiTextBuffer :: struct {
	Buf : ImVector(u8),
}

// ImGuiIO
ImGuiIO :: struct {
	ConfigFlags : ImGuiConfigFlags,
	BackendFlags : ImGuiBackendFlags,
	DisplaySize : ImVec2,
	DeltaTime : f32,
	IniSavingRate : f32,
	IniFilename : cstring,
	LogFilename : cstring,
	UserData : rawptr,
	Fonts : ^ImFontAtlas,
	FontGlobalScale : f32,
	FontAllowUserScaling : b8,
	FontDefault : ^ImFont,
	DisplayFramebufferScale : ImVec2,
	ConfigDockingNoSplit : b8,
	ConfigDockingWithShift : b8,
	ConfigDockingAlwaysTabBar : b8,
	ConfigDockingTransparentPayload : b8,
	ConfigViewportsNoAutoMerge : b8,
	ConfigViewportsNoTaskBarIcon : b8,
	ConfigViewportsNoDecoration : b8,
	ConfigViewportsNoDefaultParent : b8,
	MouseDrawCursor : b8,
	ConfigMacOSXBehaviors : b8,
	ConfigInputTrickleEventQueue : b8,
	ConfigInputTextCursorBlink : b8,
	ConfigInputTextEnterKeepActive : b8,
	ConfigDragClickToInputText : b8,
	ConfigWindowsResizeFromEdges : b8,
	ConfigWindowsMoveFromTitleBarOnly : b8,
	ConfigMemoryCompactTimer : f32,
	MouseDoubleClickTime : f32,
	MouseDoubleClickMaxDist : f32,
	MouseDragThreshold : f32,
	KeyRepeatDelay : f32,
	KeyRepeatRate : f32,
	ConfigDebugIsDebuggerPresent : b8,
	ConfigDebugBeginReturnValueOnce : b8,
	ConfigDebugBeginReturnValueLoop : b8,
	ConfigDebugIgnoreFocusLoss : b8,
	ConfigDebugIniSettings : b8,
	BackendPlatformName : cstring,
	BackendRendererName : cstring,
	BackendPlatformUserData : rawptr,
	BackendRendererUserData : rawptr,
	BackendLanguageUserData : rawptr,
	GetClipboardTextFn : rawptr,
	SetClipboardTextFn : rawptr,
	ClipboardUserData : rawptr,
	SetPlatformImeDataFn : rawptr,
	PlatformLocaleDecimalPoint : ImWchar,
	WantCaptureMouse : b8,
	WantCaptureKeyboard : b8,
	WantTextInput : b8,
	WantSetMousePos : b8,
	WantSaveIniSettings : b8,
	NavActive : b8,
	NavVisible : b8,
	Framerate : f32,
	MetricsRenderVertices : i32,
	MetricsRenderIndices : i32,
	MetricsRenderWindows : i32,
	MetricsActiveWindows : i32,
	MouseDelta : ImVec2,
	Ctx : ^ImGuiContext,
	MousePos : ImVec2,
	MouseDown : [5]b8,
	MouseWheel : f32,
	MouseWheelH : f32,
	MouseSource : ImGuiMouseSource,
	MouseHoveredViewport : ImGuiID,
	KeyCtrl : b8,
	KeyShift : b8,
	KeyAlt : b8,
	KeySuper : b8,
	KeyMods : ImGuiKeyChord,
	KeysData : [154]ImGuiKeyData,
	WantCaptureMouseUnlessPopupClose : b8,
	MousePosPrev : ImVec2,
	MouseClickedPos : [5]ImVec2,
	MouseClickedTime : [5]f64,
	MouseClicked : [5]b8,
	MouseDoubleClicked : [5]b8,
	MouseClickedCount : [5]ImU16,
	MouseClickedLastCount : [5]ImU16,
	MouseReleased : [5]b8,
	MouseDownOwned : [5]b8,
	MouseDownOwnedUnlessPopupClose : [5]b8,
	MouseWheelRequestAxisSwap : b8,
	MouseCtrlLeftAsRightClick : b8,
	MouseDownDuration : [5]f32,
	MouseDownDurationPrev : [5]f32,
	MouseDragMaxDistanceAbs : [5]ImVec2,
	MouseDragMaxDistanceSqr : [5]f32,
	PenPressure : f32,
	AppFocusLost : b8,
	AppAcceptingEvents : b8,
	BackendUsingLegacyKeyArrays : ImS8,
	BackendUsingLegacyNavInputArray : b8,
	InputQueueSurrogate : ImWchar16,
	InputQueueCharacters : ImVector(ImWchar),
}

// ImGuiTableColumnSortSpecs
ImGuiTableColumnSortSpecs :: struct {
	ColumnUserID : ImGuiID,
	ColumnIndex : ImS16,
	SortOrder : ImS16,
	SortDirection : ImGuiSortDirection,
}

// ImDrawListSplitter
ImDrawListSplitter :: struct {
	_Current : i32,
	_Count : i32,
	_Channels : ImVector(ImDrawChannel),
}

// ImDrawData
ImDrawData :: struct {
	Valid : b8,
	CmdListsCount : i32,
	TotalIdxCount : i32,
	TotalVtxCount : i32,
	CmdLists : ImVector(^ImDrawList),
	DisplayPos : ImVec2,
	DisplaySize : ImVec2,
	FramebufferScale : ImVec2,
	OwnerViewport : ^ImGuiViewport,
}

// ImFontGlyphRangesBuilder
ImFontGlyphRangesBuilder :: struct {
	UsedChars : ImVector(ImU32),
}

// ImGuiListClipper
ImGuiListClipper :: struct {
	Ctx : ^ImGuiContext,
	DisplayStart : i32,
	DisplayEnd : i32,
	ItemsCount : i32,
	ItemsHeight : f32,
	StartPosY : f32,
	TempData : rawptr,
}

// ImGuiWindowClass
ImGuiWindowClass :: struct {
	ClassId : ImGuiID,
	ParentViewportId : ImGuiID,
	FocusRouteParentWindowId : ImGuiID,
	ViewportFlagsOverrideSet : ImGuiViewportFlags,
	ViewportFlagsOverrideClear : ImGuiViewportFlags,
	TabItemFlagsOverrideSet : ImGuiTabItemFlags,
	DockNodeFlagsOverrideSet : ImGuiDockNodeFlags,
	DockingAlwaysTabBar : b8,
	DockingAllowUnclassed : b8,
}

// ImGuiPlatformImeData
ImGuiPlatformImeData :: struct {
	WantVisible : b8,
	InputPos : ImVec2,
	InputLineHeight : f32,
}

// ImGuiViewport
ImGuiViewport :: struct {
	ID : ImGuiID,
	Flags : ImGuiViewportFlags,
	Pos : ImVec2,
	Size : ImVec2,
	WorkPos : ImVec2,
	WorkSize : ImVec2,
	DpiScale : f32,
	ParentViewportId : ImGuiID,
	DrawData : ^ImDrawData,
	RendererUserData : rawptr,
	PlatformUserData : rawptr,
	PlatformHandle : rawptr,
	PlatformHandleRaw : rawptr,
	PlatformWindowCreated : b8,
	PlatformRequestMove : b8,
	PlatformRequestResize : b8,
	PlatformRequestClose : b8,
}

// ImGuiOnceUponAFrame
ImGuiOnceUponAFrame :: struct {
	RefFrame : i32,
}

// ImGuiStyle
ImGuiStyle :: struct {
	Alpha : f32,
	DisabledAlpha : f32,
	WindowPadding : ImVec2,
	WindowRounding : f32,
	WindowBorderSize : f32,
	WindowMinSize : ImVec2,
	WindowTitleAlign : ImVec2,
	WindowMenuButtonPosition : ImGuiDir,
	ChildRounding : f32,
	ChildBorderSize : f32,
	PopupRounding : f32,
	PopupBorderSize : f32,
	FramePadding : ImVec2,
	FrameRounding : f32,
	FrameBorderSize : f32,
	ItemSpacing : ImVec2,
	ItemInnerSpacing : ImVec2,
	CellPadding : ImVec2,
	TouchExtraPadding : ImVec2,
	IndentSpacing : f32,
	ColumnsMinSpacing : f32,
	ScrollbarSize : f32,
	ScrollbarRounding : f32,
	GrabMinSize : f32,
	GrabRounding : f32,
	LogSliderDeadzone : f32,
	TabRounding : f32,
	TabBorderSize : f32,
	TabMinWidthForCloseButton : f32,
	TabBarBorderSize : f32,
	TableAngledHeadersAngle : f32,
	TableAngledHeadersTextAlign : ImVec2,
	ColorButtonPosition : ImGuiDir,
	ButtonTextAlign : ImVec2,
	SelectableTextAlign : ImVec2,
	SeparatorTextBorderSize : f32,
	SeparatorTextAlign : ImVec2,
	SeparatorTextPadding : ImVec2,
	DisplayWindowPadding : ImVec2,
	DisplaySafeAreaPadding : ImVec2,
	DockingSeparatorSize : f32,
	MouseCursorScale : f32,
	AntiAliasedLines : b8,
	AntiAliasedLinesUseTex : b8,
	AntiAliasedFill : b8,
	CurveTessellationTol : f32,
	CircleTessellationMaxError : f32,
	Colors : [57]ImVec4,
	HoverStationaryDelay : f32,
	HoverDelayShort : f32,
	HoverDelayNormal : f32,
	HoverFlagsForTooltipMouse : ImGuiHoveredFlags,
	HoverFlagsForTooltipNav : ImGuiHoveredFlags,
}

// Todo(Leo): this path probably needs to configurable, if this is going to have a wider audience
foreign import cimgui "../../lib/cimgui.lib"

// Note(Leo): link_prefix is needed since otherwise there are naming collisions
// with at least user32. Also not having them would mean to modify cimgui generator
@(link_prefix = "ig", default_calling_convention = "c")
foreign cimgui {
	GetCurrentContext :: proc () -> ^ImGuiContext ---
	GetItemRectMax :: proc (pOut : ^ImVec2) ---
	GetColumnOffset :: proc (column_index : i32 = -1) -> f32 ---
	ShowDebugLogWindow :: proc (p_open : ^b8 = nil) ---
	GetFrameHeightWithSpacing :: proc () -> f32 ---
	Shortcut_Nil :: proc (key_chord : ImGuiKeyChord, flags : ImGuiInputFlags = {}) -> b8 ---
	AcceptDragDropPayload :: proc (type : cstring, flags : ImGuiDragDropFlags = {}) -> ^ImGuiPayload ---
	GetWindowDrawList :: proc () -> ^ImDrawList ---
	SetTabItemClosed :: proc (tab_or_docked_window_label : cstring) ---
	EndListBox :: proc () ---
	SetScrollX_Float :: proc (scroll_x : f32) ---
	GetStyleColorName :: proc (idx : ImGuiCol) -> cstring ---
	GetStyleColorVec4 :: proc (idx : ImGuiCol) -> ^ImVec4 ---
	GetIO :: proc () -> ^ImGuiIO ---
	SliderInt3 :: proc (label : cstring, v : [^]i32, v_min : i32, v_max : i32, format : cstring = "%d", flags : ImGuiSliderFlags = {}) -> b8 ---
	SameLine :: proc (offset_from_start_x : f32 = 0.0, spacing : f32 = -1.0) ---
	ColorEdit3 :: proc (label : cstring, col : [^]f32, flags : ImGuiColorEditFlags = {}) -> b8 ---
	IsItemVisible :: proc () -> b8 ---
	EndCombo :: proc () ---
	ArrowButton :: proc (str_id : cstring, dir : ImGuiDir) -> b8 ---
	GetDrawListSharedData :: proc () -> ^ImDrawListSharedData ---
	EndFrame :: proc () ---
	SaveIniSettingsToMemory :: proc (out_ini_size : ^u64 = nil) -> cstring ---
	LogToFile :: proc (auto_open_depth : i32 = -1, filename : cstring = nil) ---
	LoadIniSettingsFromDisk :: proc (ini_filename : cstring) ---
	IsPopupOpen_Str :: proc (str_id : cstring, flags : ImGuiPopupFlags = {}) -> b8 ---
	SetNextWindowFocus :: proc () ---
	VSliderFloat :: proc (label : cstring, size : ImVec2, v : ^f32, v_min : f32, v_max : f32, format : cstring = "%.3f", flags : ImGuiSliderFlags = {}) -> b8 ---
	PushTabStop :: proc (tab_stop : b8) ---
	PopID :: proc () ---
	Button :: proc (label : cstring, size : ImVec2 = {0, 0}) -> b8 ---
	PlotHistogram_FloatPtr :: proc (label : cstring, values : ^f32, values_count : i32, values_offset : i32 = 0, overlay_text : cstring = nil, scale_min : f32 = math.F32_MAX, scale_max : f32 = math.F32_MAX, graph_size : ImVec2 = {0, 0}, stride : i32 = size_of(f32)) ---
	Combo_Str_arr :: proc (label : cstring, current_item : ^i32, items : [^]cstring, items_count : i32, popup_max_height_in_items : i32 = -1) -> b8 ---
	Combo_Str :: proc (label : cstring, current_item : ^i32, items_separated_by_zeros : cstring, popup_max_height_in_items : i32 = -1) -> b8 ---
	ShowDemoWindow :: proc (p_open : ^b8 = nil) ---
	SetNextItemShortcut :: proc (key_chord : ImGuiKeyChord, flags : ImGuiInputFlags = {}) ---
	SliderScalarN :: proc (label : cstring, data_type : ImGuiDataType, p_data : rawptr, components : i32, p_min : rawptr, p_max : rawptr, format : cstring = nil, flags : ImGuiSliderFlags = {}) -> b8 ---
	SetNextWindowCollapsed :: proc (collapsed : b8, cond : ImGuiCond = {}) ---
	DestroyContext :: proc (ctx : ^ImGuiContext = nil) ---
	TableSetupColumn :: proc (label : cstring, flags : ImGuiTableColumnFlags = {}, init_width_or_weight : f32 = 0.0, user_id : ImGuiID = {}) ---
	EndDisabled :: proc () ---
	End :: proc () ---
	Separator :: proc () ---
	IsItemDeactivated :: proc () -> b8 ---
	Unindent :: proc (indent_w : f32 = 0.0) ---
	OpenPopup_Str :: proc (str_id : cstring, popup_flags : ImGuiPopupFlags = {}) ---
	OpenPopup_ID :: proc (id : ImGuiID, popup_flags : ImGuiPopupFlags = {}) ---
	GetTime :: proc () -> f64 ---
	DragFloat :: proc (label : cstring, v : ^f32, v_speed : f32 = 1.0, v_min : f32 = 0.0, v_max : f32 = 0.0, format : cstring = "%.3f", flags : ImGuiSliderFlags = {}) -> b8 ---
	CreateContext :: proc (shared_font_atlas : ^ImFontAtlas = nil) -> ^ImGuiContext ---
	SliderFloat3 :: proc (label : cstring, v : [^]f32, v_min : f32, v_max : f32, format : cstring = "%.3f", flags : ImGuiSliderFlags = {}) -> b8 ---
	TableAngledHeadersRow :: proc () ---
	GetScrollMaxX :: proc () -> f32 ---
	PopStyleColor :: proc (count : i32 = 1) ---
	InputInt4 :: proc (label : cstring, v : [^]i32, flags : ImGuiInputTextFlags = {}) -> b8 ---
	BeginTabItem :: proc (label : cstring, p_open : ^b8 = nil, flags : ImGuiTabItemFlags = {}) -> b8 ---
	GetFrameCount :: proc () -> i32 ---
	Selectable_Bool :: proc (label : cstring, selected : b8 = false, flags : ImGuiSelectableFlags = {}, size : ImVec2 = {0, 0}) -> b8 ---
	Selectable_BoolPtr :: proc (label : cstring, p_selected : ^b8, flags : ImGuiSelectableFlags = {}, size : ImVec2 = {0, 0}) -> b8 ---
	BeginChild_Str :: proc (str_id : cstring, size : ImVec2 = {0, 0}, child_flags : ImGuiChildFlags = {}, window_flags : ImGuiWindowFlags = {}) -> b8 ---
	BeginChild_ID :: proc (id : ImGuiID, size : ImVec2 = {0, 0}, child_flags : ImGuiChildFlags = {}, window_flags : ImGuiWindowFlags = {}) -> b8 ---
	InputText :: proc (label : cstring, buf : cstring, buf_size : u64, flags : ImGuiInputTextFlags = {}, callback : ImGuiInputTextCallback = nil, user_data : rawptr = nil) -> b8 ---
	AlignTextToFramePadding :: proc () ---
	BeginPopupContextWindow :: proc (str_id : cstring = nil, popup_flags : ImGuiPopupFlags = ImGuiPopupFlags(1)) -> b8 ---
	SetCursorPosY :: proc (local_y : f32) ---
	EndTabBar :: proc () ---
	IsAnyMouseDown :: proc () -> b8 ---
	DragIntRange2 :: proc (label : cstring, v_current_min : ^i32, v_current_max : ^i32, v_speed : f32 = 1.0, v_min : i32 = 0, v_max : i32 = 0, format : cstring = "%d", format_max : cstring = nil, flags : ImGuiSliderFlags = {}) -> b8 ---
	SliderFloat4 :: proc (label : cstring, v : [^]f32, v_min : f32, v_max : f32, format : cstring = "%.3f", flags : ImGuiSliderFlags = {}) -> b8 ---
	DockSpaceOverViewport :: proc (dockspace_id : ImGuiID = {}, viewport : ^ImGuiViewport = nil, flags : ImGuiDockNodeFlags = {}, window_class : ^ImGuiWindowClass = nil) -> ImGuiID ---
	TableNextColumn :: proc () -> b8 ---
	PushButtonRepeat :: proc (repeat : b8) ---
	EndDragDropSource :: proc () ---
	BeginMainMenuBar :: proc () -> b8 ---
	ImageButton :: proc (str_id : cstring, user_texture_id : ImTextureID, image_size : ImVec2, uv0 : ImVec2 = {0, 0}, uv1 : ImVec2 = {1, 1}, bg_col : ImVec4 = {0, 0, 0, 0}, tint_col : ImVec4 = {1, 1, 1, 1}) -> b8 ---
	TableGetColumnIndex :: proc () -> i32 ---
	IsKeyChordPressed_Nil :: proc (key_chord : ImGuiKeyChord) -> b8 ---
	SetNextWindowScroll :: proc (scroll : ImVec2) ---
	IsMouseHoveringRect :: proc (r_min : ImVec2, r_max : ImVec2, clip : b8 = true) -> b8 ---
	GetWindowSize :: proc (pOut : ^ImVec2) ---
	SetMouseCursor :: proc (cursor_type : ImGuiMouseCursor) ---
	SetScrollY_Float :: proc (scroll_y : f32) ---
	IsWindowHovered :: proc (flags : ImGuiHoveredFlags = {}) -> b8 ---
	GetCursorPos :: proc (pOut : ^ImVec2) ---
	InputTextMultiline :: proc (label : cstring, buf : cstring, buf_size : u64, size : ImVec2 = {0, 0}, flags : ImGuiInputTextFlags = {}, callback : ImGuiInputTextCallback = nil, user_data : rawptr = nil) -> b8 ---
	SliderInt2 :: proc (label : cstring, v : [^]i32, v_min : i32, v_max : i32, format : cstring = "%d", flags : ImGuiSliderFlags = {}) -> b8 ---
	TableHeadersRow :: proc () ---
	ColorConvertRGBtoHSV :: proc (r : f32, g : f32, b : f32, out_h : ^f32, out_s : ^f32, out_v : ^f32) ---
	ColorEdit4 :: proc (label : cstring, col : [^]f32, flags : ImGuiColorEditFlags = {}) -> b8 ---
	EndPopup :: proc () ---
	SliderAngle :: proc (label : cstring, v_rad : ^f32, v_degrees_min : f32 = -360.0, v_degrees_max : f32 = +360.0, format : cstring = "%.0f deg", flags : ImGuiSliderFlags = {}) -> b8 ---
	PopClipRect :: proc () ---
	IsWindowCollapsed :: proc () -> b8 ---
	GetItemRectSize :: proc (pOut : ^ImVec2) ---
	RadioButton_Bool :: proc (label : cstring, active : b8) -> b8 ---
	RadioButton_IntPtr :: proc (label : cstring, v : ^i32, v_button : i32) -> b8 ---
	GetColumnIndex :: proc () -> i32 ---
	Dummy :: proc (size : ImVec2) ---
	GetCursorStartPos :: proc (pOut : ^ImVec2) ---
	IsMouseDown_Nil :: proc (button : ImGuiMouseButton) -> b8 ---
	EndMainMenuBar :: proc () ---
	ShowIDStackToolWindow :: proc (p_open : ^b8 = nil) ---
	FindViewportByPlatformHandle :: proc (platform_handle : rawptr) -> ^ImGuiViewport ---
	SetNextItemAllowOverlap :: proc () ---
	CalcItemWidth :: proc () -> f32 ---
	GetBackgroundDrawList :: proc (viewport : ^ImGuiViewport = nil) -> ^ImDrawList ---
	LogFinish :: proc () ---
	ListBox_Str_arr :: proc (label : cstring, current_item : ^i32, items : [^]cstring, items_count : i32, height_in_items : i32 = -1) -> b8 ---
	GetCursorPosY :: proc () -> f32 ---
	ShowMetricsWindow :: proc (p_open : ^b8 = nil) ---
	EndMenuBar :: proc () ---
	LogToTTY :: proc (auto_open_depth : i32 = -1) ---
	SetWindowPos_Vec2 :: proc (pos : ImVec2, cond : ImGuiCond = {}) ---
	SetWindowPos_Str :: proc (name : cstring, pos : ImVec2, cond : ImGuiCond = {}) ---
	GetMousePos :: proc (pOut : ^ImVec2) ---
	NewFrame :: proc () ---
	SetNextFrameWantCaptureKeyboard :: proc (want_capture_keyboard : b8) ---
	GetMouseDragDelta :: proc (pOut : ^ImVec2, button : ImGuiMouseButton = {}, lock_threshold : f32 = -1.0) ---
	TableSetColumnIndex :: proc (column_n : i32) -> b8 ---
	EndTable :: proc () ---
	TableGetHoveredColumn :: proc () -> i32 ---
	SetScrollHereX :: proc (center_x_ratio : f32 = 0.5) ---
	LogToClipboard :: proc (auto_open_depth : i32 = -1) ---
	SetCurrentContext :: proc (ctx : ^ImGuiContext) ---
	SetScrollFromPosX_Float :: proc (local_x : f32, center_x_ratio : f32 = 0.5) ---
	IsMouseDoubleClicked_Nil :: proc (button : ImGuiMouseButton) -> b8 ---
	TableNextRow :: proc (row_flags : ImGuiTableRowFlags = {}, min_row_height : f32 = 0.0) ---
	BeginPopupContextVoid :: proc (str_id : cstring = nil, popup_flags : ImGuiPopupFlags = ImGuiPopupFlags(1)) -> b8 ---
	SetNextWindowClass :: proc (window_class : ^ImGuiWindowClass) ---
	BeginItemTooltip :: proc () -> b8 ---
	GetForegroundDrawList_ViewportPtr :: proc (viewport : ^ImGuiViewport = nil) -> ^ImDrawList ---
	GetScrollMaxY :: proc () -> f32 ---
	IsKeyDown_Nil :: proc (key : ImGuiKey) -> b8 ---
	CollapsingHeader_TreeNodeFlags :: proc (label : cstring, flags : ImGuiTreeNodeFlags = {}) -> b8 ---
	CollapsingHeader_BoolPtr :: proc (label : cstring, p_visible : ^b8, flags : ImGuiTreeNodeFlags = {}) -> b8 ---
	GetScrollX :: proc () -> f32 ---
	SetWindowFocus_Nil :: proc () ---
	SetWindowFocus_Str :: proc (name : cstring) ---
	IsAnyItemHovered :: proc () -> b8 ---
	ColorPicker3 :: proc (label : cstring, col : [^]f32, flags : ImGuiColorEditFlags = {}) -> b8 ---
	PushTextWrapPos :: proc (wrap_local_pos_x : f32 = 0.0) ---
	DragInt :: proc (label : cstring, v : ^i32, v_speed : f32 = 1.0, v_min : i32 = 0, v_max : i32 = 0, format : cstring = "%d", flags : ImGuiSliderFlags = {}) -> b8 ---
	BeginListBox :: proc (label : cstring, size : ImVec2 = {0, 0}) -> b8 ---
	TreePush_Str :: proc (str_id : cstring) ---
	TreePush_Ptr :: proc (ptr_id : rawptr) ---
	IsItemEdited :: proc () -> b8 ---
	Begin :: proc (name : cstring, p_open : ^b8 = nil, flags : ImGuiWindowFlags = {}) -> b8 ---
	BeginPopupModal :: proc (name : cstring, p_open : ^b8 = nil, flags : ImGuiWindowFlags = {}) -> b8 ---
	SetCursorPosX :: proc (local_x : f32) ---
	InputFloat3 :: proc (label : cstring, v : [^]f32, format : cstring = "%.3f", flags : ImGuiInputTextFlags = {}) -> b8 ---
	PopItemWidth :: proc () ---
	GetFontTexUvWhitePixel :: proc (pOut : ^ImVec2) ---
	PopButtonRepeat :: proc () ---
	Indent :: proc (indent_w : f32 = 0.0) ---
	GetDrawData :: proc () -> ^ImDrawData ---
	BeginMenuBar :: proc () -> b8 ---
	ShowStyleSelector :: proc (label : cstring) -> b8 ---
	TreeNodeEx_Str :: proc (label : cstring, flags : ImGuiTreeNodeFlags = {}) -> b8 ---
	GetFontSize :: proc () -> f32 ---
	SetNextItemOpen :: proc (is_open : b8, cond : ImGuiCond = {}) ---
	GetItemID :: proc () -> ImGuiID ---
	GetTextLineHeightWithSpacing :: proc () -> f32 ---
	IsKeyReleased_Nil :: proc (key : ImGuiKey) -> b8 ---
	ShowStyleEditor :: proc (ref : ^ImGuiStyle = nil) ---
	InputTextWithHint :: proc (label : cstring, hint : cstring, buf : cstring, buf_size : u64, flags : ImGuiInputTextFlags = {}, callback : ImGuiInputTextCallback = nil, user_data : rawptr = nil) -> b8 ---
	SetNextWindowBgAlpha :: proc (alpha : f32) ---
	TreePop :: proc () ---
	DragFloat3 :: proc (label : cstring, v : [^]f32, v_speed : f32 = 1.0, v_min : f32 = 0.0, v_max : f32 = 0.0, format : cstring = "%.3f", flags : ImGuiSliderFlags = {}) -> b8 ---
	SetWindowCollapsed_Bool :: proc (collapsed : b8, cond : ImGuiCond = {}) ---
	SetWindowCollapsed_Str :: proc (name : cstring, collapsed : b8, cond : ImGuiCond = {}) ---
	Spacing :: proc () ---
	TableGetColumnName_Int :: proc (column_n : i32 = -1) -> cstring ---
	PushItemWidth :: proc (item_width : f32) ---
	SetNextItemWidth :: proc (item_width : f32) ---
	GetDragDropPayload :: proc () -> ^ImGuiPayload ---
	ColorConvertFloat4ToU32 :: proc (in_ : ImVec4) -> ImU32 ---
	NextColumn :: proc () ---
	IsMouseClicked_Bool :: proc (button : ImGuiMouseButton, repeat : b8 = false) -> b8 ---
	GetCursorPosX :: proc () -> f32 ---
	SetNextWindowDockID :: proc (dock_id : ImGuiID, cond : ImGuiCond = {}) ---
	GetWindowWidth :: proc () -> f32 ---
	TableGetColumnFlags :: proc (column_n : i32 = -1) -> ImGuiTableColumnFlags ---
	IsRectVisible_Nil :: proc (size : ImVec2) -> b8 ---
	IsRectVisible_Vec2 :: proc (rect_min : ImVec2, rect_max : ImVec2) -> b8 ---
	GetWindowContentRegionMin :: proc (pOut : ^ImVec2) ---
	ShowAboutWindow :: proc (p_open : ^b8 = nil) ---
	InputScalarN :: proc (label : cstring, data_type : ImGuiDataType, p_data : rawptr, components : i32, p_step : rawptr = nil, p_step_fast : rawptr = nil, format : cstring = nil, flags : ImGuiInputTextFlags = {}) -> b8 ---
	GetFont :: proc () -> ^ImFont ---
	EndChild :: proc () ---
	EndDragDropTarget :: proc () ---
	TabItemButton :: proc (label : cstring, flags : ImGuiTabItemFlags = {}) -> b8 ---
	SetWindowFontScale :: proc (scale : f32) ---
	DragInt2 :: proc (label : cstring, v : [^]i32, v_speed : f32 = 1.0, v_min : i32 = 0, v_max : i32 = 0, format : cstring = "%d", flags : ImGuiSliderFlags = {}) -> b8 ---
	InputDouble :: proc (label : cstring, v : ^f64, step : f64 = 0.0, step_fast : f64 = 0.0, format : cstring = "%.6f", flags : ImGuiInputTextFlags = {}) -> b8 ---
	SaveIniSettingsToDisk :: proc (ini_filename : cstring) ---
	PushClipRect :: proc (clip_rect_min : ImVec2, clip_rect_max : ImVec2, intersect_with_current_clip_rect : b8) ---
	SetScrollHereY :: proc (center_y_ratio : f32 = 0.5) ---
	DockSpace :: proc (dockspace_id : ImGuiID, size : ImVec2 = {0, 0}, flags : ImGuiDockNodeFlags = {}, window_class : ^ImGuiWindowClass = nil) -> ImGuiID ---
	UpdatePlatformWindows :: proc () ---
	SetScrollFromPosY_Float :: proc (local_y : f32, center_y_ratio : f32 = 0.5) ---
	GetFrameHeight :: proc () -> f32 ---
	EndTabItem :: proc () ---
	StyleColorsLight :: proc (dst : ^ImGuiStyle = nil) ---
	PopStyleVar :: proc (count : i32 = 1) ---
	SliderScalar :: proc (label : cstring, data_type : ImGuiDataType, p_data : rawptr, p_min : rawptr, p_max : rawptr, format : cstring = nil, flags : ImGuiSliderFlags = {}) -> b8 ---
	SetAllocatorFunctions :: proc (alloc_func : ImGuiMemAllocFunc, free_func : ImGuiMemFreeFunc, user_data : rawptr = nil) ---
	MemAlloc :: proc (size : u64) -> rawptr ---
	GetContentRegionMax :: proc (pOut : ^ImVec2) ---
	IsWindowDocked :: proc () -> b8 ---
	DebugCheckVersionAndDataLayout :: proc (version_str : cstring, sz_io : u64, sz_style : u64, sz_vec2 : u64, sz_vec4 : u64, sz_drawvert : u64, sz_drawidx : u64) -> b8 ---
	GetWindowDockID :: proc () -> ImGuiID ---
	IsMousePosValid :: proc (mouse_pos : ^ImVec2 = nil) -> b8 ---
	GetScrollY :: proc () -> f32 ---
	TableGetColumnCount :: proc () -> i32 ---
	GetTreeNodeToLabelSpacing :: proc () -> f32 ---
	TableSetBgColor :: proc (target : ImGuiTableBgTarget, color : ImU32, column_n : i32 = -1) ---
	ColorButton :: proc (desc_id : cstring, col : ImVec4, flags : ImGuiColorEditFlags = {}, size : ImVec2 = {0, 0}) -> b8 ---
	TableSetupScrollFreeze :: proc (cols : i32, rows : i32) ---
	GetWindowHeight :: proc () -> f32 ---
	CloseCurrentPopup :: proc () ---
	DragScalar :: proc (label : cstring, data_type : ImGuiDataType, p_data : rawptr, v_speed : f32 = 1.0, p_min : rawptr = nil, p_max : rawptr = nil, format : cstring = nil, flags : ImGuiSliderFlags = {}) -> b8 ---
	SetColumnOffset :: proc (column_index : i32, offset_x : f32) ---
	Bullet :: proc () ---
	PushID_Str :: proc (str_id : cstring) ---
	PushID_StrStr :: proc (str_id_begin : cstring, str_id_end : cstring) ---
	PushID_Ptr :: proc (ptr_id : rawptr) ---
	PushID_Int :: proc (int_id : i32) ---
	GetAllocatorFunctions :: proc (p_alloc_func : ^ImGuiMemAllocFunc, p_free_func : ^ImGuiMemFreeFunc, p_user_data : ^rawptr) ---
	ResetMouseDragDelta :: proc (button : ImGuiMouseButton = {}) ---
	GetClipboardText :: proc () -> cstring ---
	LogButtons :: proc () ---
	GetMouseClickedCount :: proc (button : ImGuiMouseButton) -> i32 ---
	SetColumnWidth :: proc (column_index : i32, width : f32) ---
	InputFloat2 :: proc (label : cstring, v : [^]f32, format : cstring = "%.3f", flags : ImGuiInputTextFlags = {}) -> b8 ---
	CalcTextSize :: proc (pOut : ^ImVec2, text : cstring, text_end : cstring = nil, hide_text_after_double_hash : b8 = false, wrap_width : f32 = -1.0) ---
	GetItemRectMin :: proc (pOut : ^ImVec2) ---
	TreeNode_Str :: proc (label : cstring) -> b8 ---
	DragScalarN :: proc (label : cstring, data_type : ImGuiDataType, p_data : rawptr, components : i32, v_speed : f32 = 1.0, p_min : rawptr = nil, p_max : rawptr = nil, format : cstring = nil, flags : ImGuiSliderFlags = {}) -> b8 ---
	SetDragDropPayload :: proc (type : cstring, data : rawptr, sz : u64, cond : ImGuiCond = {}) -> b8 ---
	PopTabStop :: proc () ---
	VSliderInt :: proc (label : cstring, size : ImVec2, v : ^i32, v_min : i32, v_max : i32, format : cstring = "%d", flags : ImGuiSliderFlags = {}) -> b8 ---
	CheckboxFlags_IntPtr :: proc (label : cstring, flags : ^i32, flags_value : i32) -> b8 ---
	CheckboxFlags_UintPtr :: proc (label : cstring, flags : ^u32, flags_value : u32) -> b8 ---
	PushFont :: proc (font : ^ImFont) ---
	SmallButton :: proc (label : cstring) -> b8 ---
	SliderInt4 :: proc (label : cstring, v : [^]i32, v_min : i32, v_max : i32, format : cstring = "%d", flags : ImGuiSliderFlags = {}) -> b8 ---
	GetKeyName :: proc (key : ImGuiKey) -> cstring ---
	SetCursorScreenPos :: proc (pos : ImVec2) ---
	DragFloat2 :: proc (label : cstring, v : [^]f32, v_speed : f32 = 1.0, v_min : f32 = 0.0, v_max : f32 = 0.0, format : cstring = "%.3f", flags : ImGuiSliderFlags = {}) -> b8 ---
	BeginDragDropTarget :: proc () -> b8 ---
	SetNextWindowSizeConstraints :: proc (size_min : ImVec2, size_max : ImVec2, custom_callback : ImGuiSizeCallback = nil, custom_callback_data : rawptr = nil) ---
	SetItemDefaultFocus :: proc () ---
	IsMouseDragging :: proc (button : ImGuiMouseButton, lock_threshold : f32 = -1.0) -> b8 ---
	VSliderScalar :: proc (label : cstring, size : ImVec2, data_type : ImGuiDataType, p_data : rawptr, p_min : rawptr, p_max : rawptr, format : cstring = nil, flags : ImGuiSliderFlags = {}) -> b8 ---
	DestroyPlatformWindows :: proc () ---
	BeginMenu :: proc (label : cstring, enabled : b8 = true) -> b8 ---
	IsItemHovered :: proc (flags : ImGuiHoveredFlags = {}) -> b8 ---
	ColorConvertU32ToFloat4 :: proc (pOut : ^ImVec4, in_ : ImU32) ---
	MenuItem_Bool :: proc (label : cstring, shortcut : cstring = nil, selected : b8 = false, enabled : b8 = true) -> b8 ---
	MenuItem_BoolPtr :: proc (label : cstring, shortcut : cstring, p_selected : ^b8, enabled : b8 = true) -> b8 ---
	Image :: proc (user_texture_id : ImTextureID, image_size : ImVec2, uv0 : ImVec2 = {0, 0}, uv1 : ImVec2 = {1, 1}, tint_col : ImVec4 = {1, 1, 1, 1}, border_col : ImVec4 = {0, 0, 0, 0}) ---
	StyleColorsClassic :: proc (dst : ^ImGuiStyle = nil) ---
	EndGroup :: proc () ---
	GetVersion :: proc () -> cstring ---
	GetWindowContentRegionMax :: proc (pOut : ^ImVec2) ---
	StyleColorsDark :: proc (dst : ^ImGuiStyle = nil) ---
	BeginTooltip :: proc () -> b8 ---
	DebugTextEncoding :: proc (text : cstring) ---
	InputScalar :: proc (label : cstring, data_type : ImGuiDataType, p_data : rawptr, p_step : rawptr = nil, p_step_fast : rawptr = nil, format : cstring = nil, flags : ImGuiInputTextFlags = {}) -> b8 ---
	IsItemActive :: proc () -> b8 ---
	OpenPopupOnItemClick :: proc (str_id : cstring = nil, popup_flags : ImGuiPopupFlags = ImGuiPopupFlags(1)) ---
	IsAnyItemFocused :: proc () -> b8 ---
	BeginDragDropSource :: proc (flags : ImGuiDragDropFlags = {}) -> b8 ---
	GetWindowDpiScale :: proc () -> f32 ---
	GetColumnWidth :: proc (column_index : i32 = -1) -> f32 ---
	GetWindowViewport :: proc () -> ^ImGuiViewport ---
	IsItemClicked :: proc (mouse_button : ImGuiMouseButton = {}) -> b8 ---
	GetStateStorage :: proc () -> ^ImGuiStorage ---
	InputInt2 :: proc (label : cstring, v : [^]i32, flags : ImGuiInputTextFlags = {}) -> b8 ---
	IsKeyPressed_Bool :: proc (key : ImGuiKey, repeat : b8 = true) -> b8 ---
	SetColorEditOptions :: proc (flags : ImGuiColorEditFlags) ---
	GetTextLineHeight :: proc () -> f32 ---
	ColorPicker4 :: proc (label : cstring, col : [^]f32, flags : ImGuiColorEditFlags = {}, ref_col : ^f32 = nil) -> b8 ---
	SeparatorText :: proc (label : cstring) ---
	IsAnyItemActive :: proc () -> b8 ---
	DragInt3 :: proc (label : cstring, v : [^]i32, v_speed : f32 = 1.0, v_min : i32 = 0, v_max : i32 = 0, format : cstring = "%d", flags : ImGuiSliderFlags = {}) -> b8 ---
	NewLine :: proc () ---
	PushStyleVar_Float :: proc (idx : ImGuiStyleVar, val : f32) ---
	PushStyleVar_Vec2 :: proc (idx : ImGuiStyleVar, val : ImVec2) ---
	LoadIniSettingsFromMemory :: proc (ini_data : cstring, ini_size : u64 = 0) ---
	PlotLines_FloatPtr :: proc (label : cstring, values : ^f32, values_count : i32, values_offset : i32 = 0, overlay_text : cstring = nil, scale_min : f32 = math.F32_MAX, scale_max : f32 = math.F32_MAX, graph_size : ImVec2 = {0, 0}, stride : i32 = size_of(f32)) ---
	PopTextWrapPos :: proc () ---
	ShowFontSelector :: proc (label : cstring) ---
	Value_Bool :: proc (prefix : cstring, b : b8) ---
	Value_Int :: proc (prefix : cstring, v : i32) ---
	Value_Uint :: proc (prefix : cstring, v : u32) ---
	Value_Float :: proc (prefix : cstring, v : f32, float_format : cstring = nil) ---
	TextUnformatted :: proc (text : cstring, text_end : cstring = nil) ---
	IsWindowAppearing :: proc () -> b8 ---
	GetStyle :: proc () -> ^ImGuiStyle ---
	SliderFloat :: proc (label : cstring, v : ^f32, v_min : f32, v_max : f32, format : cstring = "%.3f", flags : ImGuiSliderFlags = {}) -> b8 ---
	IsItemDeactivatedAfterEdit :: proc () -> b8 ---
	IsWindowFocused :: proc (flags : ImGuiFocusedFlags = {}) -> b8 ---
	TableHeader :: proc (label : cstring) ---
	DebugFlashStyleColor :: proc (idx : ImGuiCol) ---
	TableGetSortSpecs :: proc () -> ^ImGuiTableSortSpecs ---
	GetContentRegionAvail :: proc (pOut : ^ImVec2) ---
	SetKeyboardFocusHere :: proc (offset : i32 = 0) ---
	SetNextWindowViewport :: proc (viewport_id : ImGuiID) ---
	IsMouseReleased_Nil :: proc (button : ImGuiMouseButton) -> b8 ---
	GetMainViewport :: proc () -> ^ImGuiViewport ---
	PushStyleColor_U32 :: proc (idx : ImGuiCol, col : ImU32) ---
	PushStyleColor_Vec4 :: proc (idx : ImGuiCol, col : ImVec4) ---
	GetPlatformIO :: proc () -> ^ImGuiPlatformIO ---
	BeginGroup :: proc () ---
	BeginDisabled :: proc (disabled : b8 = true) ---
	BeginCombo :: proc (label : cstring, preview_value : cstring, flags : ImGuiComboFlags = {}) -> b8 ---
	GetColorU32_Col :: proc (idx : ImGuiCol, alpha_mul : f32 = 1.0) -> ImU32 ---
	GetColorU32_Vec4 :: proc (col : ImVec4) -> ImU32 ---
	GetColorU32_U32 :: proc (col : ImU32, alpha_mul : f32 = 1.0) -> ImU32 ---
	GetMouseCursor :: proc () -> ImGuiMouseCursor ---
	DebugStartItemPicker :: proc () ---
	DragFloatRange2 :: proc (label : cstring, v_current_min : ^f32, v_current_max : ^f32, v_speed : f32 = 1.0, v_min : f32 = 0.0, v_max : f32 = 0.0, format : cstring = "%.3f", format_max : cstring = nil, flags : ImGuiSliderFlags = {}) -> b8 ---
	EndTooltip :: proc () ---
	InvisibleButton :: proc (str_id : cstring, size : ImVec2, flags : ImGuiButtonFlags = {}) -> b8 ---
	InputFloat :: proc (label : cstring, v : ^f32, step : f32 = 0.0, step_fast : f32 = 0.0, format : cstring = "%.3f", flags : ImGuiInputTextFlags = {}) -> b8 ---
	GetColumnsCount :: proc () -> i32 ---
	ColorConvertHSVtoRGB :: proc (h : f32, s : f32, v : f32, out_r : ^f32, out_g : ^f32, out_b : ^f32) ---
	GetCursorScreenPos :: proc (pOut : ^ImVec2) ---
	SetStateStorage :: proc (storage : ^ImGuiStorage) ---
	GetMousePosOnOpeningCurrentPopup :: proc (pOut : ^ImVec2) ---
	GetKeyPressedAmount :: proc (key : ImGuiKey, repeat_delay : f32, rate : f32) -> i32 ---
	FindViewportByID :: proc (id : ImGuiID) -> ^ImGuiViewport ---
	ShowUserGuide :: proc () ---
	InputInt :: proc (label : cstring, v : ^i32, step : i32 = 1, step_fast : i32 = 100, flags : ImGuiInputTextFlags = {}) -> b8 ---
	EndMenu :: proc () ---
	Render :: proc () ---
	IsItemToggledOpen :: proc () -> b8 ---
	IsItemFocused :: proc () -> b8 ---
	InputFloat4 :: proc (label : cstring, v : [^]f32, format : cstring = "%.3f", flags : ImGuiInputTextFlags = {}) -> b8 ---
	SetWindowSize_Vec2 :: proc (size : ImVec2, cond : ImGuiCond = {}) ---
	SetWindowSize_Str :: proc (name : cstring, size : ImVec2, cond : ImGuiCond = {}) ---
	BeginPopupContextItem :: proc (str_id : cstring = nil, popup_flags : ImGuiPopupFlags = ImGuiPopupFlags(1)) -> b8 ---
	IsItemActivated :: proc () -> b8 ---
	SliderInt :: proc (label : cstring, v : ^i32, v_min : i32, v_max : i32, format : cstring = "%d", flags : ImGuiSliderFlags = {}) -> b8 ---
	SetNextWindowSize :: proc (size : ImVec2, cond : ImGuiCond = {}) ---
	SetClipboardText :: proc (text : cstring) ---
	SliderFloat2 :: proc (label : cstring, v : [^]f32, v_min : f32, v_max : f32, format : cstring = "%.3f", flags : ImGuiSliderFlags = {}) -> b8 ---
	TableSetColumnEnabled :: proc (column_n : i32, v : b8) ---
	MemFree :: proc (ptr : rawptr) ---
	BeginPopup :: proc (str_id : cstring, flags : ImGuiWindowFlags = {}) -> b8 ---
	GetID_Str :: proc (str_id : cstring) -> ImGuiID ---
	GetID_StrStr :: proc (str_id_begin : cstring, str_id_end : cstring) -> ImGuiID ---
	GetID_Ptr :: proc (ptr_id : rawptr) -> ImGuiID ---
	DragFloat4 :: proc (label : cstring, v : [^]f32, v_speed : f32 = 1.0, v_min : f32 = 0.0, v_max : f32 = 0.0, format : cstring = "%.3f", flags : ImGuiSliderFlags = {}) -> b8 ---
	SetNextWindowPos :: proc (pos : ImVec2, cond : ImGuiCond = {}, pivot : ImVec2 = {0, 0}) ---
	InputInt3 :: proc (label : cstring, v : [^]i32, flags : ImGuiInputTextFlags = {}) -> b8 ---
	SetNextFrameWantCaptureMouse :: proc (want_capture_mouse : b8) ---
	SetCursorPos :: proc (local_pos : ImVec2) ---
	RenderPlatformWindowsDefault :: proc (platform_render_arg : rawptr = nil, renderer_render_arg : rawptr = nil) ---
	PopFont :: proc () ---
	ProgressBar :: proc (fraction : f32, size_arg : ImVec2 = {-math.F32_MIN, 0}, overlay : cstring = nil) ---
	DragInt4 :: proc (label : cstring, v : [^]i32, v_speed : f32 = 1.0, v_min : i32 = 0, v_max : i32 = 0, format : cstring = "%d", flags : ImGuiSliderFlags = {}) -> b8 ---
	BeginTable :: proc (str_id : cstring, columns : i32, flags : ImGuiTableFlags = {}, outer_size : ImVec2 = {0, 0}, inner_width : f32 = 0.0) -> b8 ---
	TableGetRowIndex :: proc () -> i32 ---
	Checkbox :: proc (label : cstring, v : ^b8) -> b8 ---
	Columns :: proc (count : i32 = 1, id : cstring = nil, border : b8 = true) ---
	SetNextWindowContentSize :: proc (size : ImVec2) ---
	BeginTabBar :: proc (str_id : cstring, flags : ImGuiTabBarFlags = {}) -> b8 ---
	GetWindowPos :: proc (pOut : ^ImVec2) ---
}

@(default_calling_convention = "c")
foreign cimgui {
	ImGuiTextBuffer_clear :: proc (self : ^ImGuiTextBuffer) ---
	ImGuiTextBuffer_size :: proc (self : ^ImGuiTextBuffer) -> i32 ---
	ImGuiTextFilter_Build :: proc (self : ^ImGuiTextFilter) ---
	ImDrawListSplitter_Split :: proc (self : ^ImDrawListSplitter, draw_list : ^ImDrawList, count : i32) ---
	ImFontAtlas_GetGlyphRangesDefault :: proc (self : ^ImFontAtlas) -> ^ImWchar ---
	ImGuiIO_ClearEventsQueue :: proc (self : ^ImGuiIO) ---
	ImDrawList_PathLineTo :: proc (self : ^ImDrawList, pos : ImVec2) ---
	ImGuiStorage_SetFloat :: proc (self : ^ImGuiStorage, key : ImGuiID, val : f32) ---
	ImFontAtlas_GetGlyphRangesThai :: proc (self : ^ImFontAtlas) -> ^ImWchar ---
	ImDrawListSplitter_Merge :: proc (self : ^ImDrawListSplitter, draw_list : ^ImDrawList) ---
	ImDrawList__PathArcToN :: proc (self : ^ImDrawList, center : ImVec2, radius : f32, a_min : f32, a_max : f32, num_segments : i32) ---
	ImFont_AddRemapChar :: proc (self : ^ImFont, dst : ImWchar, src : ImWchar, overwrite_dst : b8 = true) ---
	ImFontAtlas_GetGlyphRangesCyrillic :: proc (self : ^ImFontAtlas) -> ^ImWchar ---
	ImGuiIO_AddMouseViewportEvent :: proc (self : ^ImGuiIO, id : ImGuiID) ---
	ImDrawList_PathBezierCubicCurveTo :: proc (self : ^ImDrawList, p2 : ImVec2, p3 : ImVec2, p4 : ImVec2, num_segments : i32 = 0) ---
	ImFontGlyphRangesBuilder_GetBit :: proc (self : ^ImFontGlyphRangesBuilder, n : u64) -> b8 ---
	ImGuiPayload_IsDataType :: proc (self : ^ImGuiPayload, type : cstring) -> b8 ---
	ImDrawList_AddCircle :: proc (self : ^ImDrawList, center : ImVec2, radius : f32, col : ImU32, num_segments : i32 = 0, thickness : f32 = 1.0) ---
	ImDrawList_PrimWriteIdx :: proc (self : ^ImDrawList, idx : ImDrawIdx) ---
	ImFont_AddGlyph :: proc (self : ^ImFont, src_cfg : ^ImFontConfig, c : ImWchar, x0 : f32, y0 : f32, x1 : f32, y1 : f32, u0 : f32, v0 : f32, u1 : f32, v1 : f32, advance_x : f32) ---
	ImDrawList_PushTextureID :: proc (self : ^ImDrawList, texture_id : ImTextureID) ---
	ImDrawList_AddEllipseFilled :: proc (self : ^ImDrawList, center : ImVec2, radius : ImVec2, col : ImU32, rot : f32 = 0.0, num_segments : i32 = 0) ---
	ImFontAtlas_Build :: proc (self : ^ImFontAtlas) -> b8 ---
	ImGuiInputTextCallbackData_DeleteChars :: proc (self : ^ImGuiInputTextCallbackData, pos : i32, bytes_count : i32) ---
	ImGuiStorage_GetInt :: proc (self : ^ImGuiStorage, key : ImGuiID, default_val : i32 = 0) -> i32 ---
	ImGuiPayload_IsDelivery :: proc (self : ^ImGuiPayload) -> b8 ---
	ImDrawData_ScaleClipRects :: proc (self : ^ImDrawData, fb_scale : ImVec2) ---
	ImGuiIO_AddInputCharacter :: proc (self : ^ImGuiIO, c : u32) ---
	ImGuiListClipper_Begin :: proc (self : ^ImGuiListClipper, items_count : i32, items_height : f32 = -1.0) ---
	ImFont_GetCharAdvance :: proc (self : ^ImFont, c : ImWchar) -> f32 ---
	ImDrawList_PathBezierQuadraticCurveTo :: proc (self : ^ImDrawList, p2 : ImVec2, p3 : ImVec2, num_segments : i32 = 0) ---
	ImGuiViewport_GetCenter :: proc (pOut : ^ImVec2, self : ^ImGuiViewport) ---
	ImFontAtlas_ClearTexData :: proc (self : ^ImFontAtlas) ---
	ImDrawList_PushClipRectFullScreen :: proc (self : ^ImDrawList) ---
	ImDrawList_PathArcToFast :: proc (self : ^ImDrawList, center : ImVec2, radius : f32, a_min_of_12 : i32, a_max_of_12 : i32) ---
	ImGuiStorage_SetAllInt :: proc (self : ^ImGuiStorage, val : i32) ---
	ImGuiViewport_GetWorkCenter :: proc (pOut : ^ImVec2, self : ^ImGuiViewport) ---
	ImDrawList_PrimUnreserve :: proc (self : ^ImDrawList, idx_count : i32, vtx_count : i32) ---
	ImGuiIO_ClearInputMouse :: proc (self : ^ImGuiIO) ---
	ImGuiIO_AddInputCharactersUTF8 :: proc (self : ^ImGuiIO, str : cstring) ---
	ImGuiStorage_GetBool :: proc (self : ^ImGuiStorage, key : ImGuiID, default_val : b8 = false) -> b8 ---
	ImDrawList_PrimWriteVtx :: proc (self : ^ImDrawList, pos : ImVec2, uv : ImVec2, col : ImU32) ---
	ImGuiTextBuffer_reserve :: proc (self : ^ImGuiTextBuffer, capacity : i32) ---
	ImDrawList_AddBezierQuadratic :: proc (self : ^ImDrawList, p1 : ImVec2, p2 : ImVec2, p3 : ImVec2, col : ImU32, thickness : f32, num_segments : i32 = 0) ---
	ImFont_IsGlyphRangeUnused :: proc (self : ^ImFont, c_begin : u32, c_last : u32) -> b8 ---
	ImFontAtlas_GetGlyphRangesGreek :: proc (self : ^ImFontAtlas) -> ^ImWchar ---
	ImGuiTextRange_split :: proc (self : ^ImGuiTextRange, separator : u8, out : ^ImVector(ImGuiTextRange)) ---
	ImDrawList_PathClear :: proc (self : ^ImDrawList) ---
	ImGuiListClipper_IncludeItemByIndex :: proc (self : ^ImGuiListClipper, item_index : i32) ---
	ImDrawList__OnChangedTextureID :: proc (self : ^ImDrawList) ---
	ImDrawList_AddImage :: proc (self : ^ImDrawList, user_texture_id : ImTextureID, p_min : ImVec2, p_max : ImVec2, uv_min : ImVec2 = {0, 0}, uv_max : ImVec2 = {1, 1}, col : ImU32 = 4294967295) ---
	ImGuiInputTextCallbackData_SelectAll :: proc (self : ^ImGuiInputTextCallbackData) ---
	ImDrawList_PrimRectUV :: proc (self : ^ImDrawList, a : ImVec2, b : ImVec2, uv_a : ImVec2, uv_b : ImVec2, col : ImU32) ---
	ImDrawList_AddBezierCubic :: proc (self : ^ImDrawList, p1 : ImVec2, p2 : ImVec2, p3 : ImVec2, p4 : ImVec2, col : ImU32, thickness : f32, num_segments : i32 = 0) ---
	ImGuiTextFilter_PassFilter :: proc (self : ^ImGuiTextFilter, text : cstring, text_end : cstring = nil) -> b8 ---
	ImGuiStorage_SetVoidPtr :: proc (self : ^ImGuiStorage, key : ImGuiID, val : rawptr) ---
	ImFontGlyphRangesBuilder_AddChar :: proc (self : ^ImFontGlyphRangesBuilder, c : ImWchar) ---
	ImFontAtlas_IsBuilt :: proc (self : ^ImFontAtlas) -> b8 ---
	ImDrawData_AddDrawList :: proc (self : ^ImDrawData, draw_list : ^ImDrawList) ---
	ImFont_GrowIndex :: proc (self : ^ImFont, new_size : i32) ---
	ImGuiIO_AddKeyAnalogEvent :: proc (self : ^ImGuiIO, key : ImGuiKey, down : b8, v : f32) ---
	ImFont_CalcWordWrapPositionA :: proc (self : ^ImFont, scale : f32, text : cstring, text_end : cstring, wrap_width : f32) -> cstring ---
	ImDrawList_AddNgon :: proc (self : ^ImDrawList, center : ImVec2, radius : f32, col : ImU32, num_segments : i32, thickness : f32 = 1.0) ---
	ImFont_RenderChar :: proc (self : ^ImFont, draw_list : ^ImDrawList, size : f32, pos : ImVec2, col : ImU32, c : ImWchar) ---
	ImGuiIO_AddKeyEvent :: proc (self : ^ImGuiIO, key : ImGuiKey, down : b8) ---
	ImDrawList__OnChangedVtxOffset :: proc (self : ^ImDrawList) ---
	ImDrawList_AddLine :: proc (self : ^ImDrawList, p1 : ImVec2, p2 : ImVec2, col : ImU32, thickness : f32 = 1.0) ---
	ImDrawList_PathFillConvex :: proc (self : ^ImDrawList, col : ImU32) ---
	ImGuiStorage_SetInt :: proc (self : ^ImGuiStorage, key : ImGuiID, val : i32) ---
	ImColor_SetHSV :: proc (self : ^ImColor, h : f32, s : f32, v : f32, a : f32 = 1.0) ---
	ImDrawList_AddText_Vec2 :: proc (self : ^ImDrawList, pos : ImVec2, col : ImU32, text_begin : cstring, text_end : cstring = nil) ---
	ImDrawList_AddText_FontPtr :: proc (self : ^ImDrawList, font : ^ImFont, font_size : f32, pos : ImVec2, col : ImU32, text_begin : cstring, text_end : cstring = nil, wrap_width : f32 = 0.0, cpu_fine_clip_rect : ^ImVec4 = nil) ---
	ImGuiTextFilter_Draw :: proc (self : ^ImGuiTextFilter, label : cstring = "Filter(inc,-exc)", width : f32 = 0.0) -> b8 ---
	ImFont_RenderText :: proc (self : ^ImFont, draw_list : ^ImDrawList, size : f32, pos : ImVec2, col : ImU32, clip_rect : ImVec4, text_begin : cstring, text_end : cstring, wrap_width : f32 = 0.0, cpu_fine_clip : b8 = false) ---
	ImFont_ClearOutputData :: proc (self : ^ImFont) ---
	ImDrawList__PopUnusedDrawCmd :: proc (self : ^ImDrawList) ---
	ImFontAtlas_Clear :: proc (self : ^ImFontAtlas) ---
	ImFont_FindGlyphNoFallback :: proc (self : ^ImFont, c : ImWchar) -> ^ImFontGlyph ---
	ImDrawList_AddRect :: proc (self : ^ImDrawList, p_min : ImVec2, p_max : ImVec2, col : ImU32, rounding : f32 = 0.0, flags : ImDrawFlags = {}, thickness : f32 = 1.0) ---
	ImDrawListSplitter_Clear :: proc (self : ^ImDrawListSplitter) ---
	ImDrawData_DeIndexAllBuffers :: proc (self : ^ImDrawData) ---
	ImDrawList_PopClipRect :: proc (self : ^ImDrawList) ---
	ImFont_SetGlyphVisible :: proc (self : ^ImFont, c : ImWchar, visible : b8) ---
	ImDrawListSplitter_SetCurrentChannel :: proc (self : ^ImDrawListSplitter, draw_list : ^ImDrawList, channel_idx : i32) ---
	ImGuiPayload_Clear :: proc (self : ^ImGuiPayload) ---
	ImGuiPayload_IsPreview :: proc (self : ^ImGuiPayload) -> b8 ---
	ImFontAtlas_AddCustomRectFontGlyph :: proc (self : ^ImFontAtlas, font : ^ImFont, id : ImWchar, width : i32, height : i32, advance_x : f32, offset : ImVec2 = {0, 0}) -> i32 ---
	ImDrawList_AddTriangle :: proc (self : ^ImDrawList, p1 : ImVec2, p2 : ImVec2, p3 : ImVec2, col : ImU32, thickness : f32 = 1.0) ---
	ImGuiIO_AddMousePosEvent :: proc (self : ^ImGuiIO, x : f32, y : f32) ---
	ImFontAtlas_ClearInputData :: proc (self : ^ImFontAtlas) ---
	ImDrawList_PushClipRect :: proc (self : ^ImDrawList, clip_rect_min : ImVec2, clip_rect_max : ImVec2, intersect_with_current_clip_rect : b8 = false) ---
	ImDrawList_AddNgonFilled :: proc (self : ^ImDrawList, center : ImVec2, radius : f32, col : ImU32, num_segments : i32) ---
	ImGuiStorage_GetVoidPtrRef :: proc (self : ^ImGuiStorage, key : ImGuiID, default_val : rawptr = nil) -> ^rawptr ---
	ImDrawList_CloneOutput :: proc (self : ^ImDrawList) -> ^ImDrawList ---
	ImDrawList_PrimVtx :: proc (self : ^ImDrawList, pos : ImVec2, uv : ImVec2, col : ImU32) ---
	ImDrawList_PathLineToMergeDuplicate :: proc (self : ^ImDrawList, pos : ImVec2) ---
	ImDrawList_AddPolyline :: proc (self : ^ImDrawList, points : ^ImVec2, num_points : i32, col : ImU32, flags : ImDrawFlags, thickness : f32) ---
	ImDrawList_AddImageRounded :: proc (self : ^ImDrawList, user_texture_id : ImTextureID, p_min : ImVec2, p_max : ImVec2, uv_min : ImVec2, uv_max : ImVec2, col : ImU32, rounding : f32, flags : ImDrawFlags = {}) ---
	ImFontAtlas_AddFontFromFileTTF :: proc (self : ^ImFontAtlas, filename : cstring, size_pixels : f32, font_cfg : ^ImFontConfig = nil, glyph_ranges : ^ImWchar = nil) -> ^ImFont ---
	ImFontAtlas_CalcCustomRectUV :: proc (self : ^ImFontAtlas, rect : ^ImFontAtlasCustomRect, out_uv_min : ^ImVec2, out_uv_max : ^ImVec2) ---
	ImFontAtlas_ClearFonts :: proc (self : ^ImFontAtlas) ---
	ImDrawList_AddCircleFilled :: proc (self : ^ImDrawList, center : ImVec2, radius : f32, col : ImU32, num_segments : i32 = 0) ---
	ImFontAtlas_AddFont :: proc (self : ^ImFontAtlas, font_cfg : ^ImFontConfig) -> ^ImFont ---
	ImDrawList__ResetForNewFrame :: proc (self : ^ImDrawList) ---
	ImFontAtlas_GetGlyphRangesVietnamese :: proc (self : ^ImFontAtlas) -> ^ImWchar ---
	ImGuiStorage_GetVoidPtr :: proc (self : ^ImGuiStorage, key : ImGuiID) -> rawptr ---
	ImDrawListSplitter_ClearFreeMemory :: proc (self : ^ImDrawListSplitter) ---
	ImGuiListClipper_Step :: proc (self : ^ImGuiListClipper) -> b8 ---
	ImGuiListClipper_End :: proc (self : ^ImGuiListClipper) ---
	ImGuiIO_SetKeyEventNativeData :: proc (self : ^ImGuiIO, key : ImGuiKey, native_keycode : i32, native_scancode : i32, native_legacy_index : i32 = -1) ---
	ImDrawList__ClearFreeMemory :: proc (self : ^ImDrawList) ---
	ImFontAtlas_AddFontFromMemoryCompressedTTF :: proc (self : ^ImFontAtlas, compressed_font_data : rawptr, compressed_font_data_size : i32, size_pixels : f32, font_cfg : ^ImFontConfig = nil, glyph_ranges : ^ImWchar = nil) -> ^ImFont ---
	ImFontGlyphRangesBuilder_Clear :: proc (self : ^ImFontGlyphRangesBuilder) ---
	ImDrawList_PrimQuadUV :: proc (self : ^ImDrawList, a : ImVec2, b : ImVec2, c : ImVec2, d : ImVec2, uv_a : ImVec2, uv_b : ImVec2, uv_c : ImVec2, uv_d : ImVec2, col : ImU32) ---
	ImFontAtlas_GetCustomRectByIndex :: proc (self : ^ImFontAtlas, index : i32) -> ^ImFontAtlasCustomRect ---
	ImDrawCmd_GetTexID :: proc (self : ^ImDrawCmd) -> ImTextureID ---
	ImDrawList_PathEllipticalArcTo :: proc (self : ^ImDrawList, center : ImVec2, radius : ImVec2, rot : f32, a_min : f32, a_max : f32, num_segments : i32 = 0) ---
	ImGuiInputTextCallbackData_InsertChars :: proc (self : ^ImGuiInputTextCallbackData, pos : i32, text : cstring, text_end : cstring = nil) ---
	ImGuiStorage_GetFloatRef :: proc (self : ^ImGuiStorage, key : ImGuiID, default_val : f32 = 0.0) -> ^f32 ---
	ImFontGlyphRangesBuilder_BuildRanges :: proc (self : ^ImFontGlyphRangesBuilder, out_ranges : ^ImVector(ImWchar)) ---
	ImDrawList__TryMergeDrawCmds :: proc (self : ^ImDrawList) ---
	ImDrawList_ChannelsMerge :: proc (self : ^ImDrawList) ---
	ImFont_FindGlyph :: proc (self : ^ImFont, c : ImWchar) -> ^ImFontGlyph ---
	ImDrawList_AddTriangleFilled :: proc (self : ^ImDrawList, p1 : ImVec2, p2 : ImVec2, p3 : ImVec2, col : ImU32) ---
	ImGuiTextBuffer_empty :: proc (self : ^ImGuiTextBuffer) -> b8 ---
	ImFontAtlas_GetMouseCursorTexData :: proc (self : ^ImFontAtlas, cursor : ImGuiMouseCursor, out_offset : ^ImVec2, out_size : ^ImVec2, out_uv_border : [^]ImVec2, out_uv_fill : [^]ImVec2) -> b8 ---
	ImDrawList_PathRect :: proc (self : ^ImDrawList, rect_min : ImVec2, rect_max : ImVec2, rounding : f32 = 0.0, flags : ImDrawFlags = {}) ---
	ImFontAtlas_SetTexID :: proc (self : ^ImFontAtlas, id : ImTextureID) ---
	ImGuiTextBuffer_c_str :: proc (self : ^ImGuiTextBuffer) -> cstring ---
	ImGuiIO_AddInputCharacterUTF16 :: proc (self : ^ImGuiIO, c : ImWchar16) ---
	ImGuiIO_ClearInputKeys :: proc (self : ^ImGuiIO) ---
	ImGuiIO_AddFocusEvent :: proc (self : ^ImGuiIO, focused : b8) ---
	ImDrawList__OnChangedClipRect :: proc (self : ^ImDrawList) ---
	ImFont_IsLoaded :: proc (self : ^ImFont) -> b8 ---
	ImDrawList_GetClipRectMax :: proc (pOut : ^ImVec2, self : ^ImDrawList) ---
	ImFontGlyphRangesBuilder_SetBit :: proc (self : ^ImFontGlyphRangesBuilder, n : u64) ---
	ImDrawList_GetClipRectMin :: proc (pOut : ^ImVec2, self : ^ImDrawList) ---
	ImFontGlyphRangesBuilder_AddRanges :: proc (self : ^ImFontGlyphRangesBuilder, ranges : ^ImWchar) ---
	ImGuiInputTextCallbackData_HasSelection :: proc (self : ^ImGuiInputTextCallbackData) -> b8 ---
	ImFont_BuildLookupTable :: proc (self : ^ImFont) ---
	ImFontAtlas_GetGlyphRangesKorean :: proc (self : ^ImFontAtlas) -> ^ImWchar ---
	ImDrawList_AddImageQuad :: proc (self : ^ImDrawList, user_texture_id : ImTextureID, p1 : ImVec2, p2 : ImVec2, p3 : ImVec2, p4 : ImVec2, uv1 : ImVec2 = {0, 0}, uv2 : ImVec2 = {1, 0}, uv3 : ImVec2 = {1, 1}, uv4 : ImVec2 = {0, 1}, col : ImU32 = 4294967295) ---
	ImDrawList_AddEllipse :: proc (self : ^ImDrawList, center : ImVec2, radius : ImVec2, col : ImU32, rot : f32 = 0.0, num_segments : i32 = 0, thickness : f32 = 1.0) ---
	ImFontAtlas_GetTexDataAsAlpha8 :: proc (self : ^ImFontAtlas, out_pixels : ^^u8, out_width : ^i32, out_height : ^i32, out_bytes_per_pixel : ^i32 = nil) ---
	ImGuiStorage_SetBool :: proc (self : ^ImGuiStorage, key : ImGuiID, val : b8) ---
	ImFontAtlas_AddFontFromMemoryTTF :: proc (self : ^ImFontAtlas, font_data : rawptr, font_data_size : i32, size_pixels : f32, font_cfg : ^ImFontConfig = nil, glyph_ranges : ^ImWchar = nil) -> ^ImFont ---
	ImDrawList_AddDrawCmd :: proc (self : ^ImDrawList) ---
	ImGuiStyle_ScaleAllSizes :: proc (self : ^ImGuiStyle, scale_factor : f32) ---
	ImGuiTextFilter_Clear :: proc (self : ^ImGuiTextFilter) ---
	ImGuiStorage_GetBoolRef :: proc (self : ^ImGuiStorage, key : ImGuiID, default_val : b8 = false) -> ^b8 ---
	ImDrawList_AddQuadFilled :: proc (self : ^ImDrawList, p1 : ImVec2, p2 : ImVec2, p3 : ImVec2, p4 : ImVec2, col : ImU32) ---
	ImGuiTextBuffer_end :: proc (self : ^ImGuiTextBuffer) -> cstring ---
	ImFontAtlas_GetGlyphRangesChineseFull :: proc (self : ^ImFontAtlas) -> ^ImWchar ---
	ImDrawList_PathStroke :: proc (self : ^ImDrawList, col : ImU32, flags : ImDrawFlags = {}, thickness : f32 = 1.0) ---
	ImDrawList_ChannelsSplit :: proc (self : ^ImDrawList, count : i32) ---
	ImGuiIO_SetAppAcceptingEvents :: proc (self : ^ImGuiIO, accepting_events : b8) ---
	ImDrawList__CalcCircleAutoSegmentCount :: proc (self : ^ImDrawList, radius : f32) -> i32 ---
	ImDrawList__PathArcToFastEx :: proc (self : ^ImDrawList, center : ImVec2, radius : f32, a_min_sample : i32, a_max_sample : i32, a_step : i32) ---
	ImFontAtlas_AddFontDefault :: proc (self : ^ImFontAtlas, font_cfg : ^ImFontConfig = nil) -> ^ImFont ---
	ImFontAtlas_GetTexDataAsRGBA32 :: proc (self : ^ImFontAtlas, out_pixels : ^^u8, out_width : ^i32, out_height : ^i32, out_bytes_per_pixel : ^i32 = nil) ---
	ImGuiIO_AddMouseSourceEvent :: proc (self : ^ImGuiIO, source : ImGuiMouseSource) ---
	ImDrawList_AddCallback :: proc (self : ^ImDrawList, callback : ImDrawCallback, callback_data : rawptr) ---
	ImFontAtlas_GetGlyphRangesJapanese :: proc (self : ^ImFontAtlas) -> ^ImWchar ---
	ImDrawData_Clear :: proc (self : ^ImDrawData) ---
	ImGuiStorage_GetIntRef :: proc (self : ^ImGuiStorage, key : ImGuiID, default_val : i32 = 0) -> ^i32 ---
	ImGuiStorage_GetFloat :: proc (self : ^ImGuiStorage, key : ImGuiID, default_val : f32 = 0.0) -> f32 ---
	ImGuiTextBuffer_begin :: proc (self : ^ImGuiTextBuffer) -> cstring ---
	ImDrawList_AddRectFilledMultiColor :: proc (self : ^ImDrawList, p_min : ImVec2, p_max : ImVec2, col_upr_left : ImU32, col_upr_right : ImU32, col_bot_right : ImU32, col_bot_left : ImU32) ---
	ImFontAtlas_AddCustomRectRegular :: proc (self : ^ImFontAtlas, width : i32, height : i32) -> i32 ---
	ImGuiTextRange_empty :: proc (self : ^ImGuiTextRange) -> b8 ---
	ImFontGlyphRangesBuilder_AddText :: proc (self : ^ImFontGlyphRangesBuilder, text : cstring, text_end : cstring = nil) ---
	ImDrawList_AddQuad :: proc (self : ^ImDrawList, p1 : ImVec2, p2 : ImVec2, p3 : ImVec2, p4 : ImVec2, col : ImU32, thickness : f32 = 1.0) ---
	ImGuiListClipper_IncludeItemsByIndex :: proc (self : ^ImGuiListClipper, item_begin : i32, item_end : i32) ---
	ImDrawList_PopTextureID :: proc (self : ^ImDrawList) ---
	ImGuiTextFilter_IsActive :: proc (self : ^ImGuiTextFilter) -> b8 ---
	ImGuiStorage_BuildSortByKey :: proc (self : ^ImGuiStorage) ---
	ImDrawList_PathArcTo :: proc (self : ^ImDrawList, center : ImVec2, radius : f32, a_min : f32, a_max : f32, num_segments : i32 = 0) ---
	ImDrawList_AddConvexPolyFilled :: proc (self : ^ImDrawList, points : ^ImVec2, num_points : i32, col : ImU32) ---
	ImDrawList_AddRectFilled :: proc (self : ^ImDrawList, p_min : ImVec2, p_max : ImVec2, col : ImU32, rounding : f32 = 0.0, flags : ImDrawFlags = {}) ---
	ImFontAtlas_GetGlyphRangesChineseSimplifiedCommon :: proc (self : ^ImFontAtlas) -> ^ImWchar ---
	ImGuiStorage_Clear :: proc (self : ^ImGuiStorage) ---
	ImFontAtlas_AddFontFromMemoryCompressedBase85TTF :: proc (self : ^ImFontAtlas, compressed_font_data_base85 : cstring, size_pixels : f32, font_cfg : ^ImFontConfig = nil, glyph_ranges : ^ImWchar = nil) -> ^ImFont ---
	ImColor_HSV :: proc (pOut : ^ImColor, h : f32, s : f32, v : f32, a : f32 = 1.0) ---
	ImFont_GetDebugName :: proc (self : ^ImFont) -> cstring ---
	ImGuiInputTextCallbackData_ClearSelection :: proc (self : ^ImGuiInputTextCallbackData) ---
	ImDrawList_ChannelsSetCurrent :: proc (self : ^ImDrawList, n : i32) ---
	ImDrawList_PrimRect :: proc (self : ^ImDrawList, a : ImVec2, b : ImVec2, col : ImU32) ---
	ImGuiIO_AddMouseButtonEvent :: proc (self : ^ImGuiIO, button : i32, down : b8) ---
	ImGuiIO_AddMouseWheelEvent :: proc (self : ^ImGuiIO, wheel_x : f32, wheel_y : f32) ---
	ImDrawList_AddConcavePolyFilled :: proc (self : ^ImDrawList, points : ^ImVec2, num_points : i32, col : ImU32) ---
	ImFontAtlasCustomRect_IsPacked :: proc (self : ^ImFontAtlasCustomRect) -> b8 ---
	ImDrawList_PrimReserve :: proc (self : ^ImDrawList, idx_count : i32, vtx_count : i32) ---
	ImFont_CalcTextSizeA :: proc (pOut : ^ImVec2, self : ^ImFont, size : f32, max_width : f32, wrap_width : f32, text_begin : cstring, text_end : cstring = nil, remaining : ^^u8 = nil) ---
	ImDrawList_PathFillConcave :: proc (self : ^ImDrawList, col : ImU32) ---
}

Shortcut :: proc {
	Shortcut_Nil,
}

SetScrollX :: proc {
	SetScrollX_Float,
}

IsPopupOpen :: proc {
	IsPopupOpen_Str,
}

PlotHistogram :: proc {
	PlotHistogram_FloatPtr,
}

Combo :: proc {
	Combo_Str_arr,
	Combo_Str,
}

OpenPopup :: proc {
	OpenPopup_Str,
	OpenPopup_ID,
}

Selectable :: proc {
	Selectable_Bool,
	Selectable_BoolPtr,
}

BeginChild :: proc {
	BeginChild_Str,
	BeginChild_ID,
}

IsKeyChordPressed :: proc {
	IsKeyChordPressed_Nil,
}

SetScrollY :: proc {
	SetScrollY_Float,
}

RadioButton :: proc {
	RadioButton_Bool,
	RadioButton_IntPtr,
}

IsMouseDown :: proc {
	IsMouseDown_Nil,
}

ListBox :: proc {
	ListBox_Str_arr,
}

SetWindowPos :: proc {
	SetWindowPos_Vec2,
	SetWindowPos_Str,
}

ImDrawList_AddText :: proc {
	ImDrawList_AddText_Vec2,
	ImDrawList_AddText_FontPtr,
}

SetScrollFromPosX :: proc {
	SetScrollFromPosX_Float,
}

IsMouseDoubleClicked :: proc {
	IsMouseDoubleClicked_Nil,
}

GetForegroundDrawList :: proc {
	GetForegroundDrawList_ViewportPtr,
}

IsKeyDown :: proc {
	IsKeyDown_Nil,
}

CollapsingHeader :: proc {
	CollapsingHeader_TreeNodeFlags,
	CollapsingHeader_BoolPtr,
}

SetWindowFocus :: proc {
	SetWindowFocus_Nil,
	SetWindowFocus_Str,
}

TreePush :: proc {
	TreePush_Str,
	TreePush_Ptr,
}

TreeNodeEx :: proc {
	TreeNodeEx_Str,
}

IsKeyReleased :: proc {
	IsKeyReleased_Nil,
}

SetWindowCollapsed :: proc {
	SetWindowCollapsed_Bool,
	SetWindowCollapsed_Str,
}

TableGetColumnName :: proc {
	TableGetColumnName_Int,
}

IsMouseClicked :: proc {
	IsMouseClicked_Bool,
}

IsRectVisible :: proc {
	IsRectVisible_Nil,
	IsRectVisible_Vec2,
}

SetScrollFromPosY :: proc {
	SetScrollFromPosY_Float,
}

PushID :: proc {
	PushID_Str,
	PushID_StrStr,
	PushID_Ptr,
	PushID_Int,
}

TreeNode :: proc {
	TreeNode_Str,
}

CheckboxFlags :: proc {
	CheckboxFlags_IntPtr,
	CheckboxFlags_UintPtr,
}

MenuItem :: proc {
	MenuItem_Bool,
	MenuItem_BoolPtr,
}

IsKeyPressed :: proc {
	IsKeyPressed_Bool,
}

PushStyleVar :: proc {
	PushStyleVar_Float,
	PushStyleVar_Vec2,
}

PlotLines :: proc {
	PlotLines_FloatPtr,
}

Value :: proc {
	Value_Bool,
	Value_Int,
	Value_Uint,
	Value_Float,
}

IsMouseReleased :: proc {
	IsMouseReleased_Nil,
}

PushStyleColor :: proc {
	PushStyleColor_U32,
	PushStyleColor_Vec4,
}

GetColorU32 :: proc {
	GetColorU32_Col,
	GetColorU32_Vec4,
	GetColorU32_U32,
}

SetWindowSize :: proc {
	SetWindowSize_Vec2,
	SetWindowSize_Str,
}

GetID :: proc {
	GetID_Str,
	GetID_StrStr,
	GetID_Ptr,
}

