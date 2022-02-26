-- Update plans:
-- Detect blind items, make option in mod config menu

mod = RegisterMod("Regret Pedestals", 1)

local blindPedestalItemsInRoom = {}
local blindShopItemsInRoom = {}
-- local visibleItemsInRoom = {}
local disappearingPedestalItems = {}
local disappearingPedestalItemsFrame = {}
local disappearingShopItems = {}
local disappearingShopItemsFrame = {}

local questionMarkSprite = Sprite()
questionMarkSprite:Load("gfx/005.100_collectible.anm2",true)
questionMarkSprite:ReplaceSpritesheet(1,"gfx/items/collectibles/questionmark.png")
questionMarkSprite:LoadGraphics()
questionMarkSprite:SetFrame("Idle", 0)

local itemSprite = Sprite()
itemSprite:Load("gfx/005.100_collectible.anm2",true)

-- POST_PICKUP_UPDATE runs each update the item is in view
function mod:postPickupUpdate(entity)
    local isQuestionMark = true

    -- If item pointer is not saved to memory, add to respective array
    if not contains(blindPedestalItemsInRoom, entity) and not contains(blindShopItemsInRoom, entity) then

        -- Blind item check, credit to EID // not working and crashes game at the moment
        -- for j = -1,1,1 do
        --     for i = -71,0,3 do
        --         local qcolor = questionMarkSprite:GetTexel(Vector(j,i),nullVector,1,1)
        --         local ecolor = entitySprite:GetTexel(Vector(j,i),nullVector,1,1)
        --         if qcolor.Red ~= ecolor.Red or qcolor.Green ~= ecolor.Green or qcolor.Blue ~= ecolor.Blue then
        --             isQuestionMark = false
        --         end
        --     end
        -- end

        if isQuestionMark then
            local entitySprite = entity:GetSprite()
	        local name = entitySprite:GetAnimation()

            if name == "Idle" then
                table.insert(blindPedestalItemsInRoom, entity)
            end
            if name == "ShopIdle" then
                table.insert(blindShopItemsInRoom, entity)
            end
        else
            Isaac.ConsoleOutput("Visible item")
        end
    end
end

-- Called each update, checks if isaac has deleted any pedestals
function mod:postUpdate()
    local pedestalIndicesToRemove = {}
    local shopIndicesToRemove = {}

    -- Check around Isaac for items, remove ones that were previously in the room
    local pedestals = Isaac.FindByType(5, 100, -1, true, false)
    for index, result in ipairs(blindPedestalItemsInRoom) do
        if not contains(pedestals, result) then
            table.insert(disappearingPedestalItems, result)
            table.insert(disappearingPedestalItemsFrame, 0)
            table.insert(pedestalIndicesToRemove, index)
        end
    end

    for index, result in ipairs(blindShopItemsInRoom) do
        if not contains(pedestals, result) then
            table.insert(disappearingShopItems, result)
            table.insert(disappearingShopItemsFrame, 0)
            table.insert(shopIndicesToRemove, index)
        end
    end

    -- Remove removed items from the blind item array
    for index, result in ipairs(pedestalIndicesToRemove) do
        table.remove(blindPedestalItemsInRoom, result)
        for i, r in ipairs(pedestalIndicesToRemove) do
            if r > result then
                pedestalIndicesToRemove[i] = r-1
            end
        end
    end

    for index, result in ipairs(shopIndicesToRemove) do
        table.remove(blindShopItemsInRoom, result)
        for i, r in ipairs(shopIndicesToRemove) do
            if r > result then
                shopIndicesToRemove[i] = r-1
            end
        end
    end

end

-- Empty room data on POST_NEW_ROOM
function mod:postNewRoom()
    blindPedestalItemsInRoom = {}
    blindShopItemsInRoom = {}
    -- visibleItemInRoom = {}
    disappearingPedestalItems = {}
    disappearingPedestalItemsFrame = {}
    disappearingShopItems = {}
    disappearingShopItemsFrame = {}
end

function mod:postRender()
    for index, item in ipairs(disappearingPedestalItems) do
        if item.SubType ~= 0 then
            local itemPos = Isaac.WorldToScreen(item.Position)
            local spriteFile = Isaac.GetItemConfig():GetCollectible(item.SubType).GfxFileName

            itemSprite:ReplaceSpritesheet(1,spriteFile)
            itemSprite:LoadGraphics()
            local color = Color(1,1,1,(1- (disappearingPedestalItemsFrame[index]/60)))
            itemSprite.Color = color
            itemSprite:SetFrame("Idle", 0)

            itemPos.Y = itemPos.Y - disappearingPedestalItemsFrame[index]/10

            itemSprite:Render(itemPos, Vector(0,0), Vector(0,0))

            disappearingPedestalItemsFrame[index] = disappearingPedestalItemsFrame[index] + 1

            if disappearingPedestalItemsFrame[index] == 60 then
                table.remove(disappearingPedestalItems, index)
                table.remove(disappearingPedestalItemsFrame, index)
            end
        end
    end
    for index, item in ipairs(disappearingShopItems) do
        if item.SubType ~= 0 then
            local itemPos = Isaac.WorldToScreen(item.Position)
            local spriteFile = Isaac.GetItemConfig():GetCollectible(item.SubType).GfxFileName

            itemSprite:ReplaceSpritesheet(1,spriteFile)
            itemSprite:LoadGraphics()
            local color = Color(1,1,1,(1- (disappearingShopItemsFrame[index]/60)))
            itemSprite.Color = color
            itemSprite:SetFrame("ShopIdle", 0)

            itemPos.Y = itemPos.Y - disappearingShopItemsFrame[index]/10

            itemSprite:Render(itemPos, Vector(0,0), Vector(0,0))

            disappearingShopItemsFrame[index] = disappearingShopItemsFrame[index] + 1

            if disappearingShopItemsFrame[index] == 60 then
                table.remove(disappearingShopItems, index)
                table.remove(disappearingShopItemsFrame, index)
            end
        end
    end
end

-- Function to check if a table contains a value
function contains(table, value)
    for index, result in ipairs(table) do
        if GetPtrHash(result) == GetPtrHash(value) then
            return true
        end
    end

    return false
end

mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, mod.postPickupUpdate, PickupVariant.PICKUP_COLLECTIBLE)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.postNewRoom)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.postUpdate)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.postRender)