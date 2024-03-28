const c = @import("../c.zig");

const Context = @import("../JavaScriptCore/Context.zig");

const utils = @import("utils.zig");
const getString = utils.getString;

const Surface = @import("Surface.zig");
const Renderer = @import("Renderer.zig");
const RenderTarget = @import("RenderTarget.zig");

const View = @This();

ptr: c.ULView,

pub const Config = struct {
    ptr: c.ULViewConfig,

    ///
    /// Create view configuration with default values (see <Ultralight/platform/View.h>).
    ///
    pub fn create() Config {
        const ptr = c.ulCreateViewConfig();
        return .{ .ptr = ptr };
    }

    ///
    /// Destroy view configuration.
    ///
    pub fn destroy(self: Config) void {
        c.ulDestroyViewConfig(self.ptr);
    }
};

///
/// Create a View with certain size (in pixels).
///
/// @note  You can pass null to 'session' to use the default session.
///
pub fn create(renderer: Renderer, width: u32, height: u32, config: Config, session: c.ULSession) View {
    const ptr = c.ulCreateView(renderer.ptr, width, height, config.ptr, session);
    const view = View{ .ptr = ptr };
    return view;
}

///
/// Destroy a View.
///
pub fn destroy(self: View) void {
    c.ulDestroyView(self.ptr);
}

pub const ChangeURLEvent = struct { view: View, title: []const u8 };

pub fn setChangeURLCallback(
    self: View,
    comptime UserData: type,
    user_data: *UserData,
    comptime callback: *const fn (user_data: *UserData, event: ChangeURLEvent) void,
) void {
    const Dispatch = struct {
        fn exec(user_data_ptr: ?*anyopaque, caller: c.ULView, title: c.ULString) callconv(.C) void {
            const event = ChangeURLEvent{ .view = View{ .ptr = caller }, .title = getString(title) };
            callback(@alignCast(@ptrCast(user_data_ptr)), event);
        }
    };

    c.ulViewSetChangeURLCallback(self.ptr, &Dispatch.exec, user_data);
}

pub const ChangeTitleEvent = struct { view: View, title: []const u8 };

pub fn setChangeTitleCallback(
    self: View,
    comptime UserData: type,
    user_data: *UserData,
    comptime callback: *const fn (user_data: *UserData, event: ChangeTitleEvent) void,
) void {
    const Dispatch = struct {
        fn exec(user_data_ptr: ?*anyopaque, caller: c.ULView, title: c.ULString) callconv(.C) void {
            const event = ChangeTitleEvent{ .view = View{ .ptr = caller }, .title = getString(title) };
            callback(@alignCast(@ptrCast(user_data_ptr)), event);
        }
    };

    c.ulViewSetChangeTitleCallback(self.ptr, &Dispatch.exec, user_data);
}

pub const ChangeTooltipEvent = struct { view: View, tooltip: []const u8 };

pub fn setChangeTooltipCallback(
    self: View,
    comptime UserData: type,
    user_data: *UserData,
    comptime callback: *const fn (user_data: *UserData, event: ChangeTooltipEvent) void,
) void {
    const Dispatch = struct {
        fn exec(user_data_ptr: ?*anyopaque, caller: c.ULView, tooltip: c.ULString) callconv(.C) void {
            const event = ChangeTooltipEvent{ .view = View{ .ptr = caller }, .tooltip = getString(tooltip) };
            callback(@alignCast(@ptrCast(user_data_ptr)), event);
        }
    };

    c.ulViewSetChangeTooltipCallback(self.ptr, &Dispatch.exec, user_data);
}

pub const ChangeCursorEvent = struct { view: View, cursor: u32 };

pub fn setChangeCursorCallback(
    self: View,
    comptime UserData: type,
    user_data: *UserData,
    comptime callback: *const fn (user_data: *UserData, event: ChangeCursorEvent) void,
) void {
    const Dispatch = struct {
        fn exec(user_data_ptr: ?*anyopaque, caller: c.ULView, cursor: c.ULCursor) callconv(.C) void {
            const event = ChangeCursorEvent{ .view = View{ .ptr = caller }, .cursor = cursor };
            callback(@alignCast(@ptrCast(user_data_ptr)), event);
        }
    };

    c.ulViewSetChangeCursorCallback(self.ptr, &Dispatch.exec, user_data);
}

pub const ConsoleMessageEvent = struct {
    view: View,
    source: u32,
    level: ConsoleMessageLevel,
    message: []const u8,
    line_number: u32,
    column_number: u32,
    source_id: []const u8,
};

pub const ConsoleMessageLevel = enum(c_uint) {
    Log = c.kMessageLevel_Log,
    Warning = c.kMessageLevel_Warning,
    Error = c.kMessageLevel_Error,
    Debug = c.kMessageLevel_Debug,
    Info = c.kMessageLevel_Info,
};

pub fn setConsoleMessageCallback(
    self: View,
    comptime UserData: type,
    user_data: *UserData,
    comptime callback: *const fn (user_data: *UserData, event: ConsoleMessageEvent) void,
) void {
    const Dispatch = struct {
        fn exec(
            user_data_ptr: ?*anyopaque,
            caller: c.ULView,
            source: c.ULMessageSource,
            level: c.ULMessageLevel,
            message: c.ULString,
            line_number: u32,
            column_number: u32,
            source_id: c.ULString,
        ) callconv(.C) void {
            const event = ConsoleMessageEvent{
                .view = View{ .ptr = caller },
                .source = source,
                .level = @enumFromInt(level + 1), // TODO: ???
                .message = getString(message),
                .line_number = line_number,
                .column_number = column_number,
                .source_id = getString(source_id),
            };

            callback(@alignCast(@ptrCast(user_data_ptr)), event);
        }
    };

    c.ulViewSetAddConsoleMessageCallback(self.ptr, &Dispatch.exec, user_data);
}

pub const CreateChildViewEvent = struct {
    view: View,
    opener_url: []const u8,
    target_url: []const u8,
    is_popup: bool,
    popup_rect: struct { left: i32, right: i32, top: i32, bottom: i32 },
};

pub fn setCreateChildViewCallback(
    self: View,
    comptime UserData: type,
    user_data: *UserData,
    comptime callback: *const fn (user_data: *UserData, event: CreateChildViewEvent) ?View,
) void {
    const Dispatch = struct {
        fn exec(
            user_data_ptr: ?*anyopaque,
            caller: c.ULView,
            opener_url: c.ULString,
            target_url: c.ULString,
            is_popup: bool,
            popup_rect: c.ULIntRect,
        ) callconv(.C) c.ULView {
            const event = CreateChildViewEvent{
                .view = View{ .ptr = caller },
                .opener_url = getString(opener_url),
                .target_url = getString(target_url),
                .is_popup = is_popup,
                .popup_rect = .{ .top = popup_rect.top, .bottom = popup_rect.bottom, .left = popup_rect.left, .right = popup_rect.right },
            };

            if (callback(@alignCast(@ptrCast(user_data_ptr)), event)) |view| {
                return view.ptr;
            } else {
                return null;
            }
        }
    };

    c.ulViewSetCreateChildViewCallback(self.ptr, &Dispatch.exec, user_data);
}

pub const CreateInspectorViewEvent = struct {
    view: View,
    is_local: bool,
    inspected_url: []const u8,
};

pub fn setCreateInspectorViewCallback(
    self: View,
    comptime UserData: type,
    user_data: *UserData,
    comptime callback: *const fn (user_data: *UserData, event: CreateInspectorViewEvent) ?View,
) void {
    const Dispatch = struct {
        fn exec(
            user_data_ptr: ?*anyopaque,
            caller: c.ULView,
            is_local: bool,
            inspected_url: c.ULString,
        ) callconv(.C) c.ULView {
            const event = CreateInspectorViewEvent{
                .view = View{ .ptr = caller },
                .is_local = is_local,
                .inspected_url = getString(inspected_url),
            };

            if (callback(@alignCast(@ptrCast(user_data_ptr)), event)) |view| {
                return view.ptr;
            } else {
                return null;
            }
        }
    };

    c.ulViewSetCreateInspectorViewCallback(self.ptr, &Dispatch.exec, user_data);
}

pub const BeginLoadingEvent = struct {
    view: View,
    frame_id: u64,
    is_main_frame: bool,
    url: []const u8,
};

pub fn setBeginLoadingCallback(
    self: View,
    comptime UserData: type,
    user_data: *UserData,
    comptime callback: *const fn (user_data: *UserData, event: BeginLoadingEvent) void,
) void {
    const Dispatch = struct {
        fn exec(
            user_data_ptr: ?*anyopaque,
            caller: c.ULView,
            frame_id: u64,
            is_main_frame: bool,
            url: c.ULString,
        ) callconv(.C) void {
            const event = BeginLoadingEvent{
                .view = View{ .ptr = caller },
                .frame_id = frame_id,
                .is_main_frame = is_main_frame,
                .url = getString(url),
            };

            callback(@alignCast(@ptrCast(user_data_ptr)), event);
        }
    };

    c.ulViewSetBeginLoadingCallback(self.ptr, &Dispatch.exec, user_data);
}

pub const FinishLoadingEvent = struct {
    view: View,
    frame_id: u64,
    is_main_frame: bool,
    url: []const u8,
};

pub fn setFinishLoadingCallback(
    self: View,
    comptime UserData: type,
    user_data: *UserData,
    comptime callback: *const fn (user_data: *UserData, event: FinishLoadingEvent) void,
) void {
    const Dispatch = struct {
        fn exec(
            user_data_ptr: ?*anyopaque,
            caller: c.ULView,
            frame_id: u64,
            is_main_frame: bool,
            url: c.ULString,
        ) callconv(.C) void {
            const event = FinishLoadingEvent{
                .view = View{ .ptr = caller },
                .frame_id = frame_id,
                .is_main_frame = is_main_frame,
                .url = getString(url),
            };

            callback(@alignCast(@ptrCast(user_data_ptr)), event);
        }
    };

    c.ulViewSetFinishLoadingCallback(self.ptr, &Dispatch.exec, user_data);
}

pub const FailLoadingEvent = struct {
    view: View,
    frame_id: u64,
    is_main_frame: bool,
    url: []const u8,
    description: []const u8,
    error_domain: []const u8,
    error_code: i32,
};

pub fn setFailLoadingCallback(
    self: View,
    comptime UserData: type,
    user_data: *UserData,
    comptime callback: *const fn (user_data: *UserData, event: FailLoadingEvent) void,
) void {
    const Dispatch = struct {
        fn exec(
            user_data_ptr: ?*anyopaque,
            caller: c.ULView,
            frame_id: u64,
            is_main_frame: bool,
            url: c.ULString,
            description: c.ULString,
            error_domain: c.ULString,
            error_code: i32,
        ) callconv(.C) void {
            const event = FailLoadingEvent{
                .view = View{ .ptr = caller },
                .frame_id = frame_id,
                .is_main_frame = is_main_frame,
                .url = getString(url),
                .description = getString(description),
                .error_domain = getString(error_domain),
                .error_code = error_code,
            };

            callback(@alignCast(@ptrCast(user_data_ptr)), event);
        }
    };

    c.ulViewSetFailLoadingCallback(self.ptr, &Dispatch.exec, user_data);
}

pub const WindowObjectReadyEvent = struct {
    view: View,
    frame_id: u64,
    is_main_frame: bool,
    url: []const u8,
};

pub fn setWindowObjectReadyCallback(
    self: View,
    comptime UserData: type,
    user_data: *UserData,
    comptime callback: *const fn (user_data: *UserData, event: WindowObjectReadyEvent) void,
) void {
    const Dispatch = struct {
        fn exec(ptr: ?*anyopaque, caller: c.ULView, frame_id: u64, is_main_frame: bool, url: c.ULString) callconv(.C) void {
            const event = WindowObjectReadyEvent{ .view = View{ .ptr = caller }, .frame_id = frame_id, .is_main_frame = is_main_frame, .url = getString(url) };
            callback(@alignCast(@ptrCast(ptr)), event);
        }
    };

    c.ulViewSetWindowObjectReadyCallback(self.ptr, &Dispatch.exec, user_data);
}

pub const DOMReadyEvent = struct {
    view: View,
    frame_id: u64,
    is_main_frame: bool,
    url: []const u8,
};

pub fn setDOMReadyCallback(
    self: View,
    comptime UserData: type,
    user_data: *UserData,
    comptime callback: *const fn (user_data: *UserData, event: DOMReadyEvent) void,
) void {
    const Dispatch = struct {
        fn exec(ptr: ?*anyopaque, caller: c.ULView, frame_id: u64, is_main_frame: bool, url: c.ULString) callconv(.C) void {
            const event = DOMReadyEvent{ .view = View{ .ptr = caller }, .frame_id = frame_id, .is_main_frame = is_main_frame, .url = getString(url) };
            callback(@alignCast(@ptrCast(ptr)), event);
        }
    };

    c.ulViewSetDOMReadyCallback(self.ptr, &Dispatch.exec, user_data);
}

///
/// Get current URL.
///
/// @note Don't destroy the returned string, it is owned by the View.
///
pub fn getURL(self: View) []const u8 {
    return getString(c.ulViewGetURL(self.ptr));
}

///
/// Get current title.
///
/// @note Don't destroy the returned string, it is owned by the View.
///
pub fn getTitle(self: View) []const u8 {
    return getString(c.ulViewGetTitle(self.ptr));
}

///
/// Get the width, in pixels.
///
pub fn getWidth(self: View) u32 {
    return c.ulViewGetWidth(self.ptr);
}

///
/// Get the height, in pixels.
///
pub fn getHeight(self: View) u32 {
    return c.ulViewGetHeight(self.ptr);
}

pub fn getDisplayId(self: View) u32 {
    return c.ulViewGetDisplayId(self.ptr);
}

pub fn setDisplayId(self: View, display_id: u32) void {
    c.ulViewSetDisplayId(self.ptr, display_id);
}

///
/// Get the device scale, ie. the amount to scale page units to screen pixels.
///
/// For example, a value of 1.0 is equivalent to 100% zoom. A value of 2.0 is 200% zoom.
///
pub fn getDeviceScale(self: View) f64 {
    return c.ulViewGetDeviceScale(self.ptr);
}

///
/// Set the device scale.
///
pub fn setDeviceScale(self: View, scale: f64) void {
    c.ulViewSetDeviceScale(self.ptr, scale);
}

///
/// Check if the main frame of the page is currrently loading.
///
pub fn isLoading(self: View) bool {
    return c.ulViewIsLoading(self.ptr);
}

///
/// Get the RenderTarget for the View.
///
/// @note  Only valid if this View is GPU accelerated.
///
///        You can use this with your GPUDriver implementation to bind and display the
///        corresponding texture in your application.
///
pub fn getRenderTarget(self: View) RenderTarget {
    const ptr = c.ulViewGetRenderTarget(self.ptr);
    return .{ .ptr = ptr };
}

///
/// Get the Surface for the View (native pixel buffer that the CPU renderer draws into).
///
/// @note  This operation is only valid if you're managing the Renderer yourself (eg, you've
///        previously called ulCreateRenderer() instead of ulCreateApp()).
///
///        This function will return NULL if this View is GPU accelerated.
///
///        The default Surface is BitmapSurface but you can provide your own Surface implementation
///        via ulPlatformSetSurfaceDefinition.
///
///        When using the default Surface, you can retrieve the underlying bitmap by casting
///        ULSurface to ULBitmapSurface and calling ulBitmapSurfaceGetBitmap().
///
pub fn getSurface(self: View) Surface {
    const ptr = c.ulViewGetSurface(self.ptr);
    return .{ .ptr = ptr };
}

///
/// Load a raw string of HTML.
///
pub fn loadHTML(self: View, html_string: []const u8) void {
    c.ulViewLoadHTML(self.ptr, c.ulCreateStringUTF8(html_string.ptr, html_string.len));
}

///
/// Load a URL into main frame.
///
pub fn loadURL(self: View, url_string: []const u8) void {
    c.ulViewLoadURL(self.ptr, c.ulCreateStringUTF8(url_string.ptr, url_string.len));
}

///
/// Resize view to a certain width and height (in pixels).
///
pub fn resize(self: View, width: u32, height: u32) void {
    c.ulViewResize(self.ptr, width, height);
}

///
/// Acquire the page's JSContext for use with JavaScriptCore API.
///
pub fn lock(self: View) Context {
    const ptr = c.ulViewLockJSContext(self.ptr);
    return .{ .ptr = ptr };
}

///
/// Unlock the page's JSContext after a previous call to ulViewLockJSContext().
///
pub fn unlock(self: View) void {
    c.ulViewUnlockJSContext(self.ptr);
}

///
/// Evaluate a string of JavaScript and return result.
///
pub fn evaluateScript(self: View, js: []const u8) !void {
    var exception_string: c.ULString = null;

    const js_string = c.ulCreateStringUTF8(js.ptr, js.len);
    _ = c.ulViewEvaluateScript(self.ptr, js_string, &exception_string);

    const exception = getString(exception_string);
    if (exception.len > 0) {
        return error.Exception;
    }
}

///
/// Reload current page.
///
pub fn reload(self: View) void {
    c.ulViewReload(self.ptr);
}

///
/// Stop all page loads.
///
pub fn stop(self: View) void {
    c.ulViewStop(self.ptr);
}

///
/// Give focus to the View.
///
/// You should call this to give visual indication that the View has input focus (changes active
/// text selection colors, for example).
///
pub fn focus(self: View) void {
    c.ulViewFocus(self.ptr);
}

///
/// Remove focus from the View and unfocus any focused input elements.
///
/// You should call this to give visual indication that the View has lost input focus.
///
pub fn unfocus(self: View) void {
    c.ulViewUnfocus(self.ptr);
}

///
/// Whether or not the View has focus.
///
pub fn hasFocus(self: View) bool {
    return c.ulViewHasFocus(self.ptr);
}

///
/// Whether or not the View has an input element with visible keyboard focus (indicated by a
/// blinking caret).
///
/// You can use this to decide whether or not the View should consume keyboard input events (useful
/// in games with mixed UI and key handling).
///
pub fn hasInputFocus(self: View) bool {
    return c.ulViewHasInputFocus(self.ptr);
}
