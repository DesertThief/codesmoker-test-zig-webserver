# CodeSmoker Test: Zig Web Server (#17)

A test repository for the CodeSmoker test suite demonstrating a Zig web server using http.zig.

## Project Structure

```
├── src/
│   └── main.zig          # Main server application
├── build.zig             # Zig build configuration
└── build.zig.zon         # Zig package manifest
```

## Features

- **Zig Language**: Low-level control with high-level ergonomics
- **http.zig**: High-performance HTTP server library
- **Zero Dependencies**: No runtime dependencies
- **Memory Safe**: Compile-time safety guarantees

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | API information and endpoints |
| GET | `/todos` | Get all todos |
| GET | `/todos/:id` | Get todo by ID |
| POST | `/todos` | Create a new todo |
| PUT | `/todos/:id` | Update a todo |
| DELETE | `/todos/:id` | Delete a todo |

## Getting Started

### Prerequisites

- Zig >= 0.13.0

### Install Zig

Download from [ziglang.org/download](https://ziglang.org/download/) or use a package manager:

```bash
# macOS
brew install zig

# Ubuntu/Debian
snap install zig --classic

# Windows
winget install zig.zig
```

### Build

```bash
zig build
```

### Run

```bash
zig build run
```

Server runs at http://localhost:3000

### Run Tests

```bash
zig build test
```

## Code Example

```zig
const std = @import("std");
const httpz = @import("httpz");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var server = try httpz.Server(void).init(allocator, .{ .port = 3000 }, {});
    defer {
        server.stop();
        server.deinit();
    }

    var router = try server.router(.{});
    router.get("/", index, .{});
    router.get("/todos", getAllTodos, .{});

    try server.listen();
}

fn index(_: *httpz.Request, res: *httpz.Response) !void {
    try res.json(.{ .message = "Hello from Zig!" }, .{});
}
```

## Documentation

Built using latest documentation from:
- [Zig Language](https://ziglang.org) - Zig programming language documentation
- [http.zig](https://github.com/karlseguin/http.zig) - HTTP server library

---

*This is a CodeSmoker test repository*
