# Glocal States

Helper to declare global or local states in Neovim.

# Installation

## Lazy.nvim

```lua
{
    {
        'naughie/glocal-states.nvim',
        lazy = true,
    },
    {
        'your-plugin',
        dependencies = { 'naughie/glocal-states.nvim' },
    },
}
```


# Usage

This plugin provides four endpoints, `global()`, `tab()`, `win()` and `buf()` to declare states.

```lua
local mkstate = require("glocal-states")

local tab_local_state = mkstate.tab()

function get_state_on_current_tab()
    return tab_local_state.get()
end

function set_state_on_current_tab(new_value)
    return tab_local_state.set(new_value)
end
```

The states thus created are automatically destroyed on `TabClosed`, `WinClosed`, `BufWipeout`, respectively.


## API

### Global states

The object returned by `mkstate.global()` has two methods to interact with the inner values.
"Global" means to be shared across all the tabpages, windows, buffers.
It is essentially the same as usual variables, just with explicit getter/setter methods.

- `state.get()`: Get the internal value if it is already `set()`; otherwise return `nil`
- `state.set({new_value})`: Set the internal value
    - `{new_value}` (mandatory)


```lua
local mkstate = require("glocal-states")

local state = mkstate.global()
assert(state.get() == nil)

state.set("some value", buf_id)
assert(state.get(buf_id) == "some value")
```

```lua
local state = mkstate.win()

local current_win_id = 0
state.set(1, current_win_id)
assert(state.get() == nil)

local state = mkstate.win()
state.set(1)
assert(state.get(current_win_id) == nil)
```

### Local states

The object returned by `mkstate.<SCOPE>()` has four methods to interact with the inner values.

Here, the term "scope id" means tabpage id, window id, or buffer id.
Note that the default scope id is not equivalent to `0`, unlike most of the Neovim's standard APIs.
The default id is the value returned by `vim.api.nvim_get_current_[tabpage|win|buf]()`

- `state.get({scope_id})`: Get the internal value associated with `{scope_id}` if it is already `set()`; otherwise return `nil`
    - `{scope_id}` (optional): Defaults to the current scope id
- `state.set({new_value}, {scope_id})`: Set the internal value associated with `{scope_id}` to `{new_value}`
    - `{new_value}` (mandatory)
    - `{scope_id}` (optional): Defaults to the current scope id
- `state.clear({scope_id})`: Remove the internal value associated with `{scope_id}` (if any)
    - `{scope_id}` (optional): Defaults to the current scope id
- `state.clear_all()`: Remove all of the internal values



Basic usage:
```lua
local mkstate = require("glocal-states")

local state = mkstate.buf()

local buf_id = 1

assert(state.get(buf_id) == nil)

state.set("some value", buf_id)
assert(state.get(buf_id) == "some value")

state.set({ foo = true }, buf_id)
state.get(buf_id).foo = false
assert(state.get(buf_id).foo == false)

state.clear(buf_id)
assert(state.get(buf_id) == nil)
```

The current scode id and `0` are not equivalent:
```lua
local mkstate = require("glocal-states")

local state = mkstate.win()

local current_win_id = 0
state.set(1, current_win_id)
assert(state.get() == nil)

local state = mkstate.win()
state.set(1)
assert(state.get(current_win_id) == nil)
```

The current scode id and `nvim_get_current_*` are equivalent:
```lua
local mkstate = require("glocal-states")

local state = mkstate.win()

state.set(1)
assert(state.get(vim.api.nvim_get_current_win()) == 1)
```
