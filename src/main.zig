const std = @import("std");
const httpz = @import("httpz");

// Todo struct
const Todo = struct {
    id: usize,
    name: []const u8,
    is_complete: bool,
};

// Global todo list (simple in-memory storage)
var todos: std.ArrayList(Todo) = undefined;
var next_id: usize = 1;
var gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined;

pub fn main() !void {
    gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Initialize todos list
    todos = std.ArrayList(Todo).init(allocator);
    defer todos.deinit();

    // Add some initial todos
    try todos.append(Todo{ .id = next_id, .name = "Learn Zig", .is_complete = false });
    next_id += 1;
    try todos.append(Todo{ .id = next_id, .name = "Build a web server", .is_complete = false });
    next_id += 1;

    // Initialize HTTP server
    var server = try httpz.Server(void).init(allocator, .{ .port = 3000 }, {});
    defer {
        server.stop();
        server.deinit();
    }

    // Set up custom handlers
    server.notFound(notFound);
    server.errorHandler(errorHandler);

    // Set up routes
    var router = try server.router(.{});
    router.get("/", index, .{});
    router.get("/todos", getAllTodos, .{});
    router.get("/todos/:id", getTodoById, .{});
    router.post("/todos", createTodo, .{});
    router.put("/todos/:id", updateTodo, .{});
    router.delete("/todos/:id", deleteTodo, .{});

    std.debug.print("\n\x1b[32m⚡ Zig HTTP server is running at http://localhost:3000\x1b[0m\n\n", .{});

    // Start the server (blocking)
    try server.listen();
}

fn index(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    try res.json(.{
        .message = "Welcome to Zig HTTP Server!",
        .endpoints = .{
            .get_todos = "GET /todos",
            .get_todo = "GET /todos/:id",
            .create_todo = "POST /todos",
            .update_todo = "PUT /todos/:id",
            .delete_todo = "DELETE /todos/:id",
        },
    }, .{});
}

fn getAllTodos(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    try res.json(todos.items, .{});
}

fn getTodoById(req: *httpz.Request, res: *httpz.Response) !void {
    const id_str = req.param("id") orelse {
        res.status = 400;
        res.body = "Missing id parameter";
        return;
    };

    const id = std.fmt.parseInt(usize, id_str, 10) catch {
        res.status = 400;
        res.body = "Invalid id parameter";
        return;
    };

    for (todos.items) |todo| {
        if (todo.id == id) {
            res.status = 200;
            try res.json(todo, .{});
            return;
        }
    }

    res.status = 404;
    res.body = "Todo not found";
}

fn createTodo(req: *httpz.Request, res: *httpz.Response) !void {
    if (req.body()) |body| {
        // Parse JSON body (simplified)
        _ = body;
        const new_todo = Todo{
            .id = next_id,
            .name = "New Todo",
            .is_complete = false,
        };
        next_id += 1;
        try todos.append(new_todo);

        res.status = 201;
        try res.json(new_todo, .{});
    } else {
        res.status = 400;
        res.body = "Missing request body";
    }
}

fn updateTodo(req: *httpz.Request, res: *httpz.Response) !void {
    const id_str = req.param("id") orelse {
        res.status = 400;
        res.body = "Missing id parameter";
        return;
    };

    const id = std.fmt.parseInt(usize, id_str, 10) catch {
        res.status = 400;
        res.body = "Invalid id parameter";
        return;
    };

    for (todos.items) |*todo| {
        if (todo.id == id) {
            todo.is_complete = true;
            res.status = 204;
            return;
        }
    }

    res.status = 404;
    res.body = "Todo not found";
}

fn deleteTodo(req: *httpz.Request, res: *httpz.Response) !void {
    const id_str = req.param("id") orelse {
        res.status = 400;
        res.body = "Missing id parameter";
        return;
    };

    const id = std.fmt.parseInt(usize, id_str, 10) catch {
        res.status = 400;
        res.body = "Invalid id parameter";
        return;
    };

    for (todos.items, 0..) |todo, i| {
        if (todo.id == id) {
            _ = todos.orderedRemove(i);
            res.status = 204;
            return;
        }
    }

    res.status = 404;
    res.body = "Todo not found";
}

fn notFound(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 404;
    res.body = "Not Found";
}

fn errorHandler(_: *httpz.Request, res: *httpz.Response, err: anyerror) void {
    res.status = 500;
    res.body = "Internal Server Error";
    std.log.err("httpz error: {}", .{err});
}

test "todo struct" {
    const todo = Todo{
        .id = 1,
        .name = "Test todo",
        .is_complete = false,
    };
    try std.testing.expectEqual(@as(usize, 1), todo.id);
    try std.testing.expectEqualStrings("Test todo", todo.name);
    try std.testing.expectEqual(false, todo.is_complete);
}
