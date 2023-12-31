//?
//? Entity datas tructure

const std = @import("std");

const ComponentTag = @import("component.zig").ComponentTag;
const Component = @import("component.zig").Component;

const Logger = @import("utils/log.zig");

const ComponentList = @import("component.zig").ComponentList;

/// Glorified Component container.
pub const Entity = struct {
    var _counter: u32 = 0;

    id: u32,
    components: ComponentList,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, components: ?[]const Component) !Self {
        var self = Self{
            .id = Self.getNewId(),
            .components = ComponentList.init(allocator),
        };
        if (components) |complist| {
            try self.addManyComponent(complist);
        }

        return self;
    }

    inline fn getNewId() u32 {
        Self._counter += 1;
        return Self._counter;
    }

    // Wrapper methods around the internal component list

    pub inline fn addComponent(self: *Self, component: Component) !void {
        const CTag = std.meta.activeTag(component);
        if (self.components.indexer.contains(CTag)) {
            // Just log and let it slide for now. We may or may not want to
            // treat this as an error in the future.
            Logger.warn("Replacing component of type {} on entity {}", .{ CTag, self });
        }
        return self.components.add(component);
    }

    pub inline fn addManyComponent(self: *Self, components: []const Component) !void {
        for (components) |component| {
            try self.addComponent(component);
        }
    }

    pub inline fn hasComponent(self: Self, comptime CT: ComponentTag) bool {
        return self.components.has(CT);
    }

    pub inline fn getComponent(self: Self, comptime CT: ComponentTag) !Component.TypeFromTag(CT) {
        return self.components.get(CT);
    }

    pub inline fn getComponentPtr(self: Self, comptime CT: ComponentTag) !*Component.TypeFromTag(CT) {
        return self.components.getPtr(CT);
    }

    pub fn dbgprint(self: Self) !void {
        Logger.info("### Entity ID<{}>", .{self.id});

        Logger.info("Via self.components.items:", .{});
        for (self.components._items.items) |c| {
            Logger.info("  Type: {}\n         Val: {}\n         @ {*}", .{ @TypeOf(c), c, &c });
        }

        Logger.info("Via getComponent:", .{});
        const v = try self.getComponent(.Visible);
        const p = try self.getComponent(.Position);
        Logger.info("  Type: {}\n         Val: {}\n         @ {*}", .{ @TypeOf(v), v, &v });
        Logger.info("  Type: {}\n         Val: {}\n         @ {*}", .{ @TypeOf(p), p, &p });

        Logger.info("Via getComponentPtr:", .{});
        const vptr = try self.getComponentPtr(.Visible);
        const pptr = try self.getComponentPtr(.Position);
        Logger.info("  Type: {}\n         Val: {}\n         @ {*}", .{ @TypeOf(vptr), vptr, vptr });
        Logger.info("  Type: {}\n         Val: {}\n         @ {*}", .{ @TypeOf(pptr), pptr, pptr });
    }

    // pub fn format(self: Entity, arg1: anytype, arg2: anytype, writer: anytype) !void {
    //     _ = arg1;
    //     _ = arg2;
    //     _ = self;
    //     _ = try writer.write("LOL");
    // }

    pub fn destroy(self: Entity) void {
        self.components.deinit();
    }
};
