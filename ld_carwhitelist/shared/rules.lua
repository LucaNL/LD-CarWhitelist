-- The rules, shared by client and server. Pure functions apart from joaat.

Rules = {}

local index -- built once: model hash -> { group indexes }, class -> { group indexes }

--- Natives return signed hashes; a pasted unsigned one (e.g. 2046537925) would never match. Use signed everywhere.
local function signed(hash)
    hash = tonumber(hash) or 0
    if hash > 0x7FFFFFFF then hash = hash - 0x100000000 end
    return hash
end

function Rules.build()
    index = { byModel = {}, byClass = {} }
    for gi, group in ipairs(type(Config.Groups) == 'table' and Config.Groups or {}) do
        for _, model in ipairs(type(group.models) == 'table' and group.models or {}) do
            local hash = signed(type(model) == 'number' and model or joaat(tostring(model)))
            index.byModel[hash] = index.byModel[hash] or {}
            table.insert(index.byModel[hash], gi)
        end
        for _, class in ipairs(type(group.classes) == 'table' and group.classes or {}) do
            class = tonumber(class)
            if class then
                index.byClass[class] = index.byClass[class] or {}
                table.insert(index.byClass[class], gi)
            end
        end
    end
    return index
end

--- Group indexes that contain this vehicle (by model, and by class when a class is given).
function Rules.groupsFor(model, class)
    if not index then Rules.build() end
    local out, seen = {}, {}
    for _, list in ipairs({ index.byModel[signed(model)] or {}, class and index.byClass[class] or {} }) do
        for _, gi in ipairs(list) do
            if not seen[gi] then seen[gi] = true; out[#out + 1] = gi end
        end
    end
    return out
end

--- Does this job give access to the group? job = { name, grade, onDuty } (onDuty nil = unknown, counts as on duty)
function Rules.jobAllows(group, job)
    if type(job) ~= 'table' or not job.name or type(group.jobs) ~= 'table' then return false end
    local minGrade = group.jobs[job.name]
    if minGrade == nil then return false end
    if minGrade == true then minGrade = 0 end
    if (tonumber(job.grade) or 0) < (tonumber(minGrade) or 0) then return false end
    if group.onDuty and job.onDuty == false then return false end
    return true
end

--- Is this seat locked for a player who has access to the groups in `allowed` (set of group indexes)?
--- Returns nil when the player may use it, otherwise the group that locks it (for its label).
function Rules.lockedBy(groups, allowed, seat)
    if #groups == 0 then return nil end
    for _, gi in ipairs(groups) do
        if allowed and allowed[gi] then return nil end -- access to any of the groups is enough
    end
    for _, gi in ipairs(groups) do
        local group = Config.Groups[gi]
        if group.seats == 'all' or seat == -1 then return group end
    end
    return nil
end

--- Label of a group for messages.
function Rules.label(group)
    return group and group.label or 'authorised staff'
end
