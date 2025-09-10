local M = {}

M.global = function()
    local state = {}

    state.get = function()
        return state.value
    end

    state.set = function(value)
        local prev_value = state.value
        state.value = value
        return prev_value
    end

    return state
end

local local_state_list = {
    tab = {},
    win = {},
    buf = {},
}

local scope_id_or_current = {
    tab = function(scope_id)
        if scope_id then return scope_id end
        return vim.api.nvim_get_current_tabpage()
    end,

    win = function(scope_id)
        if scope_id then return scope_id end
        return vim.api.nvim_get_current_win()
    end,

    buf = function(scope_id)
        if scope_id then return scope_id end
        return vim.api.nvim_get_current_buf()
    end,
}

local function metabuild_local(scope_id_or_current)
    local state = { values = {} }

    state.get = function(scope_id)
        local t = scope_id_or_current(scope_id)
        local inscope = state.values[t]
        if not inscope then return end
        return inscope.value
    end

    state.set = function(value, scope_id)
        local t = scope_id_or_current(scope_id)
        local inscope = state.values[t]
        if inscope then
            local prev_value = inscope.value
            inscope.value = value
            return prev_value
        else
            state.values[t] = { value = value }
        end
    end

    state.clear = function(scope_id)
        local t = scope_id_or_current(scope_id)
        state.values[t] = nil
    end

    state.clear_if = function(filter, scope_id)
        local t = scope_id_or_current(scope_id)
        local inscope = state.values[t]
        if inscope and inscope.value and filter(inscope.value) then
            state.values[t] = nil
        end
    end

    state.clear_all = function()
        state.values = {}
    end

    state.iter = function()
        local iter_func, state, control_var = pairs(state.values)

        return function()
            local scope_id, new_val = iter_func(state, control_var)
            control_var = scope_id

            if scope_id == nil then return end
            return scope_id, new_val.value
        end
    end

    state.iter_mut = function(callback)
        for scope_id, val in pairs(state.values) do
            local new_val = callback(scope_id, val and val.value)
            val.value = new_val
        end
    end

    return state
end

M.tab = function()
    local state = metabuild_local(scope_id_or_current.tab)
    table.insert(local_state_list.tab, state)

    return state
end

M.win = function()
    local state = metabuild_local(scope_id_or_current.win)
    table.insert(local_state_list.win, state)

    return state
end

M.buf = function()
    local state = metabuild_local(scope_id_or_current.buf)
    table.insert(local_state_list.buf, state)

    return state
end

local augroup = vim.api.nvim_create_augroup('NaughieGlocalStates', { clear = true })
vim.api.nvim_create_autocmd('TabClosed', {
    group = augroup,
    callback = function(ev)
        local scope = tonumber(ev.file)
        for _, state in ipairs(local_state_list.tab) do
            state.clear(scope)
        end
    end,
})
vim.api.nvim_create_autocmd('WinClosed', {
    group = augroup,
    callback = function(ev)
        local scope = tonumber(ev.file)
        for _, state in ipairs(local_state_list.win) do
            state.clear(scope)
        end
    end,
})
vim.api.nvim_create_autocmd('BufWipeout', {
    group = augroup,
    callback = function(ev)
        local scope = tonumber(ev.buf)
        for _, state in ipairs(local_state_list.buf) do
            state.clear(scope)
        end
    end,
})

return M
