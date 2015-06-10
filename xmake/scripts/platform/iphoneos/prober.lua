--!The Automatic Cross-platform Build Tool
-- 
-- XMake is free software; you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation; either version 2.1 of the License, or
-- (at your option) any later version.
-- 
-- XMake is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with XMake; 
-- If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
-- 
-- Copyright (C) 2009 - 2015, ruki All rights reserved.
--
-- @author      ruki
-- @file        prober.lua
--

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local utils     = require("base/utils")
local string    = require("base/string")
local tools     = require("tools/tools")
local config    = require("base/config")
local global    = require("base/global")

-- define module: prober
local prober = prober or {}

-- probe the architecture
function prober._probe_arch()

    -- get the architecture
    local arch = config.get("arch")

    -- ok? 
    if arch then return true end

    -- init the default architecture
    config.set("arch", "armv7")

    -- ok
    return true
end

-- probe the xcode application directory
function prober._probe_xcode()

    -- get the xcode directory
    local xcode_dir = config.get("xcode_dir")

    -- ok? 
    if xcode_dir then return true end

    -- clear it first
    xcode_dir = nil

    -- attempt to get the default directory 
    if not xcode_dir then
        if os.isdir("/Applications/Xcode.app") then
            xcode_dir = "/Applications/Xcode.app"
        end
    end

    -- attempt to match the other directories
    if not xcode_dir then
        local dirs = os.match("/Applications/Xcode*.app", true)
        if dirs and table.getn(dirs) ~= 0 then
            xcode_dir = dirs[1]
        end
    end

    -- probe ok? update it
    if xcode_dir then
        config.set("xcode_dir", xcode_dir)
    else
        -- failed
        utils.error("The Xcode directory is unknown now, please config it first!")
        utils.error("    - xmake config --xcode_dir=xxx")
        utils.error("or  - xmake global --xcode_dir=xxx")
        return false
    end

    -- ok
    return true
end

-- probe the xcode sdk version
function prober._probe_xcode_sdkver()

    -- get the xcode sdk version
    local xcode_sdkver = config.get("xcode_sdkver")

    -- ok? 
    if xcode_sdkver then return true end

    -- clear it first
    xcode_sdkver = nil

    -- attempt to match the directory
    if not xcode_sdkver then
        local dirs = os.match(config.get("xcode_dir") .. "/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS*.sdk", true)
        if dirs then
            for _, dir in ipairs(dirs) do
                xcode_sdkver = string.match(dir, "%d+%.%d+")
                if xcode_sdkver then break end
            end
        end
    end

    -- probe ok? update it
    if xcode_sdkver then
        config.set("xcode_sdkver", xcode_sdkver)
    else
        -- failed
        utils.error("The Xcode SDK version is unknown now, please config it first!")
        utils.error("    - xmake config --xcode_sdkver=xxx")
        utils.error("or  - xmake global --xcode_sdkver=xxx")
        return false
    end

    -- ok
    return true
end

-- probe the ccache
function prober._probe_ccache()

    -- ok? 
    local ccache_enable = config.get("ccache")
    if ccache_enable and config.get("__ccache") then return true end

    -- disable?
    if type(ccache_enable) == "boolean" and not ccache_enable then
        config.set("__ccache", nil)
        return true
    end

    -- probe the ccache path
    local ccache_path = tools.probe("ccache", {"/usr/bin", "/usr/local/bin", "/opt/bin", "/opt/local/bin"})

    -- probe ok? update it
    if ccache_path then
        config.set("ccache", true)
        config.set("__ccache", ccache_path)
    else
        config.set("ccache", false)
    end

    -- ok
    return true
end

-- probe the project configure 
function prober.config()

    -- probe the architecture
    if not prober._probe_arch() then return end

    -- probe the xcode application directory
    if not prober._probe_xcode() then return end

    -- probe the xcode sdk version
    if not prober._probe_xcode_sdkver() then return end

    -- probe the ccache
    if not prober._probe_ccache() then return end

end

-- probe the global configure 
function prober.global()

    -- probe the xcode application directory
    if not prober._probe_xcode() then return end

    -- probe the ccache
    if not prober._probe_ccache() then return end

end

-- return module: prober
return prober