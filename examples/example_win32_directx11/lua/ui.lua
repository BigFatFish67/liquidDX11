-- Lua-owned UI entry point for the staged Dear ImGui migration.
-- The native host is intentionally limited to platform/rendering services; this
-- module owns page selection, UI state, and page composition.

local UI = {}

UI.state = {
    page = "general",
    logged_in = true,
    search = "",
    profile = { status = 1, theme = 1 },
    settings = {},
}

UI.pages = {
    { id = "general",   title = "General",   module = "pages.general" },
    { id = "display",   title = "Display",   module = "pages.display" },
    { id = "battery",   title = "Battery",   module = "pages.battery" },
    { id = "storage",   title = "Storage",   module = "pages.storage" },
    { id = "customize", title = "Customize", module = "pages.customize" },
    { id = "profile",   title = "View Profile", module = "pages.profile" },
    { id = "account",   title = "Account Settings", module = "pages.account" },
    { id = "launchpad", title = "Apps",      module = "pages.launchpad" },
    { id = "surface",   title = "Surfaces",  module = "pages.surface" },
}

local loaded_pages = {}

local function load_page(entry)
    if not loaded_pages[entry.id] then
        local ok, page_or_error = pcall(require, entry.module)
        if not ok then
            return nil, page_or_error
        end
        assert(type(page_or_error) == "table" and type(page_or_error.draw) == "function",
            "Lua page must return a table with a draw(ui, state) function: " .. entry.module)
        loaded_pages[entry.id] = page_or_error
    end
    return loaded_pages[entry.id]
end

function UI.find_page(id)
    for i = 1, #UI.pages do
        if UI.pages[i].id == id then
            return UI.pages[i], i
        end
    end
end

function UI.set_page(id)
    if UI.find_page(id) then
        UI.state.page = id
        return true
    end
    return false
end

-- `ui` is the narrow native bridge supplied by the host. It is expected to
-- expose card/layout/widgets and must not expose Win32 or D3D objects to Lua.
function UI.draw(ui)
    assert(type(ui) == "table", "native UI bridge is required")

    local current = UI.find_page(UI.state.page) or UI.pages[1]
    local selected = ui.sidebar(UI.pages, current.id, UI.state)
    if selected then
        UI.set_page(selected)
        current = UI.find_page(UI.state.page) or current
    end

    ui.begin_card("dashboard")
    ui.search_field(UI.state, "search", "Search")
    ui.begin_content()

    local page, err = load_page(current)
    if page then
        page.draw(ui, UI.state)
    else
        ui.section(current.title)
        ui.text("Could not load Lua page: " .. tostring(err), "error")
    end

    ui.end_content()
    ui.end_card()
end

return UI
