local Sea = ...
local DataModule = {} do
    DataModule.Islands = {
        {
            ['Pirate Starter'] = CFrame.new(1077, 16, 1439),
            ['Marine Starter'] = CFrame.new(-2922, 41, 2111),
            ['Jungle'] = CFrame.new(-1439, 62, 8),
            ['Colosseum'] = CFrame.new(-1664, 151, -3245),
            ['Frozen Village'] = CFrame.new(1221, 138, -1487),
            ['Desert'] = CFrame.new(1058, 52, 4491),
            ['Fountain City'] = CFrame.new(5269, 56, 4061),
            ['Marine Fortress'] = CFrame.new(-5094, 263, 4414),
            ['Middle Town'] = CFrame.new(-849, 74, 1625),
            ['Pirate Village'] = CFrame.new(-1151, 65, 4160),
            ['Underwater City'] = CFrame.new(61318, 19, 1525),
            ['Whirlpool'] = CFrame.new(4344, 21, -1883),
            ['Prison'] = CFrame.new(5316, 89, 699),
            ['Lower Skyland'] = CFrame.new(-5050, 278, -2732),
            ['Middle Skyland'] = CFrame.new(-4654, 873, -1762),
            ['Upper Skyland'] = CFrame.new(-7654, 5623, -1071)
        },
        {
            ['Kingdom of Rose'] = CFrame.new(-385, 319, 463),
            ['Green Zone'] = CFrame.new(-2435, 73, -3250),
            ['Hot and Cold'] = CFrame.new(-5507, 82, -5165),
            ['Cursed Ship'] = CFrame.new(916, 126, 33073),
            ['Snow Mountain'] = CFrame.new(1008, 446, -4906),
            ['Ice Castle'] = CFrame.new(6146, 484, -6729),
            ['Dark Arena'] = CFrame.new(3892, 14, -3616),
            ['Graveyard Island'] = CFrame.new(-5722, 9, -963),
            ['Forgotten Island'] = CFrame.new(-3026, 319, -10083),
            ['North Pole'] = CFrame.new(-5397, 12, 1454),
        },
        {
            ['Submerged Island'] = CFrame.new(9952, -1887, 9678),
            ['Tiki Outpost'] = CFrame.new(-16928, 9, 437),
            ['Castle on the Sea'] = CFrame.new(-5086, 315, -2974),
            ['Hydra Island'] = CFrame.new(5164, 1174, 222),
            ['Peanut Island'] = CFrame.new(-2111, 193, -10243),
            ['Ice Cream Island'] = CFrame.new(-801, 210, -10999),
            ['Cake Loaf'] = CFrame.new(-1748, 489, -12360),
            ['Chocolate Island'] = CFrame.new(256, 124, -12549),
            ['North Pole'] = CFrame.new(-906, 89, -14666),
            ['Port Town'] = CFrame.new(-390, 11, 5244),
            ['Great Tree'] = CFrame.new(3295, 776, -6281),
            ['Haunted Castle'] = CFrame.new(-9499, 500, 6009),
            ['Floating Turtle'] = CFrame.new(-12310, 1163, -9968)
        },
    }

    DataModule.Places = {
        {
            ["Cyborg's Domain"] = CFrame.new(6271, 71, 4000),
            ["Thunder God's Domain"] = CFrame.new(-7989, 5814, -2030),
            ["Saber Expert's Domain"] = CFrame.new(-1425, 30, -14)
        },
        {
            ['Cafe'] = CFrame.new(-377, 73, 290),
            ['Basement Cafe'] = CFrame.new(-350, 16, 242),
            ['Mansion'] = CFrame.new(-392, 374, 720),
            ["Swan's Room"] = CFrame.new(2462, 15, 695),
            ['Raid'] = CFrame.new(-6535, 310, -4745),
            ['Labs'] = CFrame.new(-5548, 224, -5899),
            ['Colosseum'] = CFrame.new(-1822, 46, 1411),
        },
        {
            ["Beautiful Pirate's Domain"] = CFrame.new(5339, 22, -328),
            ['Head Castle on the Sea'] = CFrame.new(-5421, 1090, -2666),
            ['Mansion'] = CFrame.new(-12552, 337, -7504),
            ['Dragon Dojo'] = CFrame.new(5701, 1207, 924),
            ['Friendly Arena'] = CFrame.new(5012, 59, -1571),
            ['Waterfall'] = CFrame.new(5174, 8, 1191),
            ['Head of Great Tree'] = CFrame.new(3070, 2281, -7335)
        },
        {}
    }

    DataModule.Materials = {
        {
            ["Fish Tail"] = { "Fishman Warrior", "Fishman Commando" },
            ["Magma Ore"] = { "Military Soldier", "Military Spy" },
            ["GunPowder"] = { "Brute", "Pirate" },
            ["Angel Wings"] = { "God's Guard" },
            ["Scrap Metal"] = { "Brute" },
            ["Leather"] = { "Brute" }
        },
        {
            ["Ectoplasm"] = { 'Ship Steward', 'Ship Officer', 'Ship Engineer', 'Ship Deckhand' },
            ["Mystic Droplet"] = { "Water Fighter", "Sea Soldier" },
            ["Radioactive Material"] = { "Factory Staff" },
            ["Scrap Metal"] = { "Swan Pirate" },
            ["Magma Ore"] = { "Magma Ninja" },
            ["Vampire Fang"] = { "Vampire" }
        },
        {
            ["Conjured Cocoa"] = { "Cocoa Warrior", "Chocolate Bar Battler", "Sweet Thief", "Candy Rebel" },
            ["Dragon Scale"] = { "Dragon Crew Archer", "Dragon Crew Warrior" },
            ["Fish Tail"] = { "Fishman Raider", "Fishman Captain" },
            ["Mini Tusk"] = { "Mythological Pirate" },
            ["Gunpowder"] = { "Pistol Billionaire" },
            ["Scrap Metal"] = { "Jungle Pirate" },
            ["Demonic Wisp"] = { "Demonic Soul" }
        }
    }

    DataModule.Shops = {
        ["Ability"] = {
            ["Buy Geppo"] = { "BuyHaki", "Geppo" },
            ["Buy Buso"] = { "BuyHaki", "Buso" },
            ["Buy Soru"] = { "BuyHaki", "Soru" },
            ["Buy Ken"] = { "KenTalk", "Buy" },
        },
        ["Sword"] = {
            ["Buy Katana"] = { "BuyItem", "Katana" },
            ["Buy Cutlass"] = { "BuyItem", "Cutlass" },
            ["Buy Dual Katana"] = { "BuyItem", "Dual Katana" },
            ["Buy Iron Mace"] = { "BuyItem", "Iron Mace" },
            ["Buy Triple Katana"] = { "BuyItem", "Triple Katana" },
            ["Buy Pipe"] = { "BuyItem", "Pipe" },
            ["Buy Dual-Headed Blade"] = { "BuyItem", "Dual-Headed Blade" },
            ["Buy Soul Cane"] = { "BuyItem", "Soul Cane" },
            ["Buy Bisento"] = { "BuyItem", "Bisento" },
        },
        ["Gun"] = {
            ["Buy Musket"] = { "BuyItem", "Musket" },
            ["Buy Slingshot"] = { "BuyItem", "Slingshot" },
            ["Buy Flintlock"] = { "BuyItem", "Flintlock" },
            ["Buy Refined Slingshot"] = { "BuyItem", "Refined Slingshot" },
            ["Buy Dual Flintlock"] = { "BuyItem", "Dual Flintlock" },
            ["Buy Cannon"] = { "BuyItem", "Cannon" },
            ["Buy Kabucha"] = { "BlackbeardReward", "Slingshot", "2" },
        },
        ["Accessories"] = {
            ["Buy Black Cape"] = { "BuyItem", "Black Cape" },
            ["Buy Swordsman Hat"] = { "BuyItem", "Swordsman Hat" },
            ["Buy Tomoe Ring"] = { "BuyItem", "Tomoe Ring" },
        },
        ["Race"] = {
            ["Ghoul Race"] = { "Ectoplasm", "Change", 4 },
            ["Cyborg Race"] = { "CyborgTrainer", "Buy" },
        },
    }

    DataModule.Bosses = {
        {
            "The Gorilla King",
            "Chef",
            "Yeti",
            "Mob Leader",
            "Vice Admiral",
            "Warden",
            "Chief Warden",
            "Swan",
            "Magma Admiral",
            "Fishman Lord",
            "Wysper",
            "Thunder God",
            "Cyborg",
            "Saber Expert"
        },
        {
            "Diamond",
            "Jeremy",
            "Orbitus",
            "Don Swan",
            "Smoke Admiral",
            "Cursed Captain",
            "Darkbeard",
            "Order",
            "Awakened Ice Admiral",
            "Tide Keeper"
        },
        {
            "Stone",
            "Hydra Leader",
            "Kilo Admiral",
            "Captain Elephant",
            "Beautiful Pirate",
            "rip_indra True Form",
            "Longma",
            "Soul Reaper",
            "Cake Queen"
        }
    }
end

DataModule.Currently = {
    Islands = DataModule.Islands[Sea],
    Places = DataModule.Places[Sea],
    Materials = DataModule.Materials[Sea],
    Bosses = DataModule.Bosses[Sea],
}

function DataModule:GetNames(Name)
    local Data = self.Currently[Name]
    local List = {}

    if #Data > 0 then
        for i = 1, #Data do List[i] = Data[i] end
    else
        for Key in Data do List[#List + 1] = Key end
    end

    return List
end

DataModule.MaterialNames = DataModule:GetNames("Materials")
DataModule.IslandNames = DataModule:GetNames("Islands")
DataModule.PlaceNames = DataModule:GetNames("Places")
DataModule.BosseNames = DataModule:GetNames("Bosses")

return DataModule
