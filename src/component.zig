//?
//? Base Component struct and utils.
//?

const std = @import("std");

pub const ComponentError = error{
    NotFound,
};

/// Alias for Component's enum tag type
pub const ComponentTag = @typeInfo(Component).Union.tag_type.?;

/// Base component struct.
/// TODO: dynamic generation of the tagged union from the concrete component
/// defs.
pub const Component = union(enum) {
    PLAYER: PlayerComponent,
    POSITION: PositionComponent,
    VISIBLE: VisibleComponent,

    const Self = @This();

    /// Helper to return the concrete type associated with the given Tag
    pub inline fn TypeFromTag(comptime CT: ComponentTag) type {
        return std.meta.fields(Component)[@intFromEnum(CT)].type;
    }
};

/// Component container.
/// Backed by a dynamic ArrayList (for growable, contiguous storage)
/// and a HashMap indexer for direct lookup.
/// TODO: Benchmark and compare with a single HashMap storage. I suspect
/// the current version will be more efficient, but don't actually have any
/// idea...
pub const ComponentList = struct {
    indexer: std.AutoArrayHashMap(ComponentTag, usize),
    comps: std.ArrayList(Component),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) ComponentList {
        return .{
            .indexer = std.AutoArrayHashMap(ComponentTag, usize).init(allocator),
            .comps = std.ArrayList(Component).init(allocator),
        };
    }

    pub inline fn add(self: *Self, component: Component) !void {
        const CTag = std.meta.activeTag(component);
        try self.indexer.put(CTag, self.comps.items.len);
        try self.comps.append(component);
    }

    pub fn addMany(self: *Self, components: []const Component) !void {
        for (components) |c| {
            try self.add(c);
        }
    }

    pub inline fn has(self: Self, comptime CTag: ComponentTag) bool {
        return self.indexer.contains(CTag);
    }

    pub fn get(self: Self, comptime CTag: ComponentTag) !Component.TypeFromTag(CTag) {
        const index = self.indexer.get(CTag);
        if (index) |idx| {
            return @field(self.comps.items[idx], @tagName(CTag));
        } else {
            return ComponentError.NotFound;
        }
    }

    // FIXME: this is an almost exact duplicate of getComponent (defined above).
    // We should just reuse getComponent and return a pointer to its result,
    // but this fails because we end up returning a pointer to the temporary,
    // stack allocated value returned by getComponent instead of the actual
    // array item.
    pub fn getPtr(self: Self, comptime CTag: ComponentTag) !*Component.TypeFromTag(CTag) {
        const index = self.indexer.get(CTag);
        if (index) |idx| {
            return &@field(self.comps.items[idx], @tagName(CTag));
        } else {
            return ComponentError.NotFound;
        }
    }

    pub fn _getPtr(self: Self, comptime CTag: ComponentTag) !*Component.TypeFromTag(CTag) {
        _ = self;
        // return try &@call(.always_inline, Self.get, .{ self, CTag });
        // const c = try @call(.always_inline, Self.get, .{ self, CTag });
        // return &c;
    }

    pub fn remove(self: Self, comptime CTag: ComponentTag) void {
        _ = CTag;
        _ = self;
        @compileError("Not Implemented");
    }

    pub fn deinit(self: Self) void {
        // AutoArrayHashMap.deinit crashes if indexer is const (such as when
        // accessed directly through self) for some reason.
        // Assigning it to a var local fixes the problem.
        var indexer = self.indexer;
        indexer.deinit();
        self.comps.deinit();
    }
};

// -------------------- Actual component definitions ------------------------

const Vec2 = @import("math.zig").Vec2;

// TODO: generate component struct from this
// zig fmt: off
const ComponentDefs = .{
    .{ .tag_name = "Player", .type = void },
    .{ .tag_name = "Visible", 
        .type = struct {
            visible: bool,
            glyph: u8,
        } 
    },
    .{ .tag_name = "Position", .type = Vec2(i32) },
};
// zig fmt: on

pub const PlayerComponent = void;

pub const PositionComponent = Vec2(i32);

pub const VisibleComponent = struct {
    visible: bool = true,
    glyph: u8,
};
