//?
//? Scopped faced for std.log
//

const std = @import("std");

const BarbarLogger = std.log.scoped(.barbarlib);

pub const debug = BarbarLogger.debug;
pub const info = BarbarLogger.info;
pub const warn = BarbarLogger.warn;
pub const err = BarbarLogger.err;
